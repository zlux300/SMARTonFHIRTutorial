Class HLHTPKG.Util.XMLValid Extends %RegisteredObject
{

ClassMethod Valid(fileName As %String = "c:\temp\1.xml", docName As %String = "PatientInfoRegister") As %String
{
	k ^HLHTTemp(docName)
	s tSC = $$$OK
	#dim tR as %XML.TextReader
	s tSC = ##class(%XML.TextReader).ParseFile(fileName,.tR)
	w:$$$ISERR(tSC) $System.OBJ.DisplayError(tSC)
	while tR.Read(){
		if (tR.NodeType = "element"){
			s path = tR.Path
     	for a = 1:1:tR.AttributeCount {
    		d tR.MoveToAttributeIndex(a)
				s atr = path_"/@"_tR.LocalName
				s strValue = tR.Value
				s ^HLHTTemp(docName,atr)=strValue
     }
		}	
	}
	
	
	//s tSC = ##class(%XML.XPATH.Document).CreateFromFile(fileName,.tDoc,,,,,"nsp urn:hl7-org:v3")
	//w:$$$ISERR(tSC) $System.OBJ.DisplayError(tSC)
	
	NEW SQLCODE,%ROWCOUNT,%ROWID,%msg
	
	//&sql(select id, node,Cardinality,Flag,Expression,FixedValue,MetaDatatype,Reference into :Allfields() from HLHTPKG_Valid.Pattern where DocName = :docName)
	&sql(declare c1 cursor for 
		select node,Cardinality,Flag,Expression,FixedValue,MetaDatatype,Reference 
		into :Allfields() 
		from HLHTPKG_Valid.Pattern
		where DocName = :docName
	)
  
  &sql(Open c1)
  	q:(SQLCODE'=0)
  &sql(fetch c1)
  
  while(SQLCODE = 0){
	  	s node = $zstrip(Allfields(9),"*WC")
	  	s nodeValue = ^HLHTTemp(docName,node)
	  	s cardinality = $zstrip(Allfields(2),"*WC")
	  	if '..ValidCard(nodeValue, cardinality){
		  	d ..WriteLog(docName,node,"规则id /"_Allfields(1)_"/, 基数验证失败: 节点值为 /"_nodeValue_"/, 基数值应为 /"_cardinality_"/")
	  	}else{
		  	s flag = $zstrip($zcvt(Allfields(7),"U"),"*W")
		  	if (flag="FIX"){
		  		s fixedValue = Allfields(6)
			  	d:('..ValidFix(nodeValue,fixedValue)) ..WriteLog(docName,node,"固定值验证失败: 节点值为 /"_nodeValue_"/, 固定值应为 /"_fixedValue_"/")
		  	}elseif(flag="EXPRESSION"){
			  	s expression = Allfields(5)
			  	s metaDatatype = Allfields(8)
			  	if '..ValidExpression(nodeValue,expression,metaDatatype){
				  	d ..WriteLog(docName,node,"规则id /"_Allfields(1)_"/, 标识符格式验证失败：节点值为 /"_nodeValue_"/, 格式应为 /"_metaDatatype_"|"_expression_"/")
			  	}
		  	}elseif(flag="REF"){
		  		s reference = Allfields(10)
			  	if '..ValidRef(nodeValue,reference,.msg){
				  	d ..WriteLog(docName,node,msg)
			  	}
		  	}else {
				  	d ..WriteLog(docName,node,"规则id /"_Allfields(1)_"/, 校验规则表 HLHTPKG_Valid.Pattern 中的 Flag 字段值不合规：flag 值为 /"_flag_"/")
		  	}
	  	}
  		&sql(fetch c1)
  }
  &sql(close c1)
  
  q 1
}

ClassMethod ValidCard(value As %String, cardinality As %String) As %Boolean
{
	s lowCard = $p(cardinality,"..")
	q:(value="") 'lowCard
	q 1
}

ClassMethod ValidFix(value As %String, fix As %String) As %Boolean
{
	q value = fix
}

ClassMethod ValidExpression(value As %String, express As %String, metaDatatype As %String) As %Boolean
{
	s mDT = $zcvt(metaDatatype,"U")
	if mDT="S1"{
		if express["AN"{
			s pat = $e(express,3,*)_"AN"
		}else {
			s pat = $e(express,2,*)_$e(express,1)
		}
		s:$f(pat,"..") pat=$replace(pat,"..",".")
		q value?@pat
		
	}elseif mDT="DT"{
		s n = $e(value,3,*)
		q:(n=14) value?14N
		q:(n-15) value?8N1"T"6N
	}else{
	}
	q 1
}

ClassMethod ValidRef(value As %String, ref As %String, ByRef msg As %String) As %Boolean
{
}

ClassMethod WriteLog(docName As %String, node As %String, msg As %String)
{
}

}
