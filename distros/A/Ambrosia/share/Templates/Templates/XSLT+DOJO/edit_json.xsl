<?xml version="1.0" encoding="UTF-8" ?>
<xslt:stylesheet version="1.0" 
	xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/TransformAlias"
	xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xslt:import href="incDojo_JS_Css.xsl" />

<xslt:output method="xml" indent="yes" />
<xslt:namespace-alias stylesheet-prefix="xsl" result-prefix="xslt"/>

<xslt:include href="../../incName.xsl" />
<xslt:include href="../../incUtils.xsl" />

<xslt:template match="/">

<xsl:stylesheet version="1.0">
<xsl:output method="html" indent="yes" />
<xsl:include href="_message.xsl"/>

<xsl:template match="/"><xsl:text disable-output-escaping="yes">&lt;!DOCTYPE HTML>
</xsl:text>
<html lang="en">
	<xslt:if test="boolean(/Application/@Language)">
		<xslt:attribute name="lang">
			<xslt:value-of select="/Application/@Language"/>
		</xslt:attribute>
	</xslt:if>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<xslt:apply-imports/>

		<script type="text/javascript">
			require([
			"dijit/dijit",
			"dijit/form/Form",
			"dijit/form/Button",
			"dijit/form/ValidationTextBox",
<xslt:for-each select="//atns:Application/atns:Entity/atns:Field[not(@Type=preceding-sibling::atns:Field/@Type)]">
	<xslt:choose>
		<xslt:when test="@Type='String' and not(@Hidden)">
			"dijit/form/TextBox",</xslt:when>

		<xslt:when test="@Type='Number'">
			"dijit/form/NumberTextBox",</xslt:when>

		<xslt:when test="@Type='Double' and not(@Hidden)">
		</xslt:when>

		<xslt:when test="@Type='Bool' and not(@Hidden)">
			"dijit/form/CheckBox",</xslt:when>

		<xslt:when test="@Type='Date' or @Type='Datetime'">
			"dojo/date", "dojo/date/locale",
			"dijit/form/DateTextBox",</xslt:when>

		<xslt:when test="@type='Text'">
			"dijit/form/Textarea",
			"dijit/form/SimpleTextarea",
			"dijit/Editor",</xslt:when>
	</xslt:choose>
</xslt:for-each>
			"dojo/domReady!", "dojo/parser"]);
		</script>
	</head>
	<body class="claro">
		<xsl:apply-templates select="//repository/mng_EWM" />
		<xsl:apply-templates>
			<xslt:attribute name="select"><xslt:value-of select="$UcAppName" /></xslt:attribute>
		</xsl:apply-templates>
	</body>
</html>
</xsl:template>

<xsl:template>
	<xslt:attribute name="match"><xslt:value-of select="$UcAppName" /></xslt:attribute>
	<xslt:variable name="entityName" select="translate(//atns:Application/atns:Entity/@Name[1], $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>
	<form method="POST">
		<xsl:attribute name="action"><xsl:value-of select="@script" />/<xslt:value-of select="$entityName" /></xsl:attribute>
		<!-- input type="hidden" name="m" value=''>
			<xslt:attribute name="value">/save/<xslt:value-of select="$entityName" /></xslt:attribute>
		</input -->
		<xsl:apply-templates select="repository"/>

<!-- xsl:variable name="onClick">onClick:function(){ validate(); }</xsl:variable>
<button data-dojo-type="dijit.form.Button">
	<xsl:attribute name="data-dojo-props"><xsl:value-of select="$onClick" /></xsl:attribute>
	Validate form!</button -->
<button data-dojo-type="dijit.form.Button" data-dojo-props="type:'submit', value:'Submit'">Submit</button>

	</form>
</xsl:template>

<xsl:template match="repository">
	<xslt:apply-templates select="atns:Application/atns:Entity" />
</xsl:template>

</xsl:stylesheet>

</xslt:template>

<xslt:template match="atns:Application/atns:Entity">
	<xslt:variable name="label">
		<xslt:choose>
			<xslt:when test="not(@Label) or @Label!=''">
				<xslt:value-of select="@Label"/>
			</xslt:when>
			<xslt:otherwise>
				<xslt:value-of select="@Name"/>
			</xslt:otherwise>
		</xslt:choose>
	</xslt:variable>
	<xslt:for-each select="atns:Key">
		<input type="hidden">
			<xslt:attribute name="name"><xslt:value-of select="atns:FieldRef/@Name"/></xslt:attribute>
		<xsl:attribute name="value"><xsl:value-of>
				<xslt:attribute name="select"><xslt:value-of select="concat('./',../@Name,'/@',atns:FieldRef/@Name)"/></xslt:attribute>
			</xsl:value-of>
			</xsl:attribute>
		</input>
	</xslt:for-each>
	<table>
		<tr><td colspan="2" align="center" style="font-size: 1.2em;">
			<b>Edit <xslt:value-of select="$label" /></b>
		</td></tr>
		<xslt:apply-templates select="atns:Field"/>

		<xslt:variable name="EId" select="@Id" />
		<xslt:if test="boolean(/atns:Application/atns:EntitysRef/atns:Entity[@Id=/atns:Application/atns:Relations/atns:Relation[@RefId=$EId]/atns:EntityRef/@RefId and @Type='BIND'])">
		<xslt:apply-templates
			select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=/atns:Application/atns:Relations/atns:Relation[@RefId=$EId]/atns:EntityRef/@RefId and @Type='BIND']" mode="bind" />
		</xslt:if>
	</table>
</xslt:template>

<xslt:template match="atns:Field">
	<xslt:variable name="EId" select="../@Id" />
	<xslt:variable name="FName" select="@Name" />
	<xslt:variable name="label">
		<xslt:choose>
			<xslt:when test="not(@Label) or @Label!=''">
				<xslt:value-of select="@Label"/>
			</xslt:when>
			<xslt:when test="boolean(/atns:Application/atns:Relations/atns:Relation/atns:EntityRef[@RefId=$EId and @To=$FName]/../@Type)">
				<xslt:value-of select="/atns:Application/atns:Relations/atns:Relation/atns:EntityRef[@RefId=$EId]/../@Type"/>
			</xslt:when>
			<xslt:otherwise>
				<xslt:value-of select="@Name"/>
			</xslt:otherwise>
		</xslt:choose>
	</xslt:variable>

	<xslt:if test="not(@Hidden)">
	<tr>
		<td><xslt:value-of select="$label"/></td>
		<td>
			<xslt:variable name="name" select="@Name"/>
			<xslt:variable name="value" select="concat('./',../@Name,'/@',@Name)"/>
			<xslt:variable name="in_type">
				<xslt:choose>
					<xslt:when test="boolean(@Hidden)">hidden</xslt:when>
					<xslt:otherwise>text</xslt:otherwise>
				</xslt:choose>
			</xslt:variable>

			<xslt:choose>
				<xslt:when test="@Type='Bool'">
					<xsl:variable name="value">,value:1</xsl:variable>
				</xslt:when>
				<xslt:otherwise>
					<xsl:variable name="value">,value:&quot;<xsl:value-of><xslt:attribute name="select"><xslt:value-of select="$value" /></xslt:attribute></xsl:value-of>&quot;</xsl:variable>
				</xslt:otherwise>
			</xslt:choose>
			<xsl:variable name="regExp"><xslt:if test="@Type='Email'">,regExp:<xsl:variable name="s24"><xslt:value-of select="concat('{','2,4}')" /></xsl:variable>&quot;[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]<xsl:value-of select="$s24" />&quot;</xslt:if></xsl:variable>
			<xslt:variable name="dojoProps">id:&quot;id_<xslt:value-of select="$name" />&quot;,name:&quot;<xslt:value-of select="$name" />&quot;,type:&quot;<xslt:value-of select="$in_type" />&quot;,trim:true,maxLength:&quot;<xslt:value-of select="@Size" />&quot;,promptMessage:&quot;<xslt:value-of select="@Title" />&quot;</xslt:variable>
<!--xslt:variable name="dojoProps">
id:&quot;id_<xslt:value-of select="$name" />&quot;,
name:&quot;<xslt:value-of select="$name" />&quot;,
type:&quot;<xslt:value-of select="$in_type" />&quot;,
trim:true,
maxLength:&quot;<xslt:value-of select="@Size" />&quot;,
promptMessage:&quot;<xslt:value-of select="@Title" />&quot;</xslt:variable-->

			<xslt:variable name="dojoType">
				<xslt:choose>
					<xslt:when test="@Type='Email'">dijit.form.ValidationTextBox</xslt:when>
					<xslt:when test="@Type='String'">dijit.form.ValidationTextBox</xslt:when>
					<xslt:when test="@Type='Number'">dijit.form.NumberTextBox</xslt:when>
					<xslt:when test="@Type='Double'">dijit.form.NumberTextBox</xslt:when>
					<xslt:when test="@Type='Date'">dijit.form.DateTextBox</xslt:when>
					<xslt:when test="@Type='Datetime'">dijit.form.DateTextBox</xslt:when>
					<xslt:when test="@Type='Bool'">dijit.form.CheckBox</xslt:when>
					<xslt:otherwise>dijit.form.ValidationTextBox</xslt:otherwise>
				</xslt:choose>
			</xslt:variable>

<xslt:choose>
	<xslt:when test="boolean(/atns:Application/atns:Relations/atns:Relation/atns:EntityRef[@RefId=$EId and @To=$name])">
<xslt:apply-templates
	select="/atns:Application/atns:Relations/atns:Relation/atns:EntityRef[@RefId=$EId and @To=$name]" mode="ref" />
	</xslt:when>

	<xslt:when test="@Type='Bool'">
<input type="checkbox" id="" data-dojo-type="dijit.form.CheckBox" name="" value="1">
	<xsl:attribute name="id">id_<xslt:value-of select="$name" /></xsl:attribute>
	<xsl:attribute name="name"><xslt:value-of select="$name" /></xsl:attribute>
</input>
	</xslt:when>
	<xslt:otherwise>
		<input style="width:15em;">
			<xslt:if test="@Type='Date' or @Type='Datetime'">
				<xslt:attribute name="lang">
					<xslt:choose>
						<xslt:when test="boolean(/atns:Application/@Language)"><xslt:value-of select="/atns:Application/@Language"/></xslt:when>
						<xslt:otherwise>en-us</xslt:otherwise>
					</xslt:choose>
				</xslt:attribute>
			</xslt:if>
			<xslt:attribute name="title">
				<xslt:value-of select="@Title"/>
			</xslt:attribute>
			<xslt:attribute name="data-dojo-type">
				<xslt:value-of select="$dojoType"/>
			</xslt:attribute>
			<xsl:attribute name="data-dojo-props"><xsl:value-of>
					<xslt:attribute name="select">
					<xslt:value-of select="concat('concat(',$s_q,$dojoProps,$s_q,',', '$', 'value,', '$', 'regExp', ')')"/>
			</xslt:attribute></xsl:value-of></xsl:attribute>
		</input>
	</xslt:otherwise>
</xslt:choose>
		</td>
	</tr>
	</xslt:if>
</xslt:template>

<xslt:template match="atns:EntityRef" mode="ref" >
<xslt:variable name="p_ref_id" select="../@RefId"/>
<xslt:variable name="ref_id" select="./@RefId"/>
<xslt:variable name="ref" select="concat('./', /atns:Application/atns:Entity[@Id=$ref_id]/@Name, '/@', @To)" />

<xsl:variable name="value_ref">
	<xsl:choose>
		<xsl:when >
			<xslt:attribute name="test">
				<xslt:value-of select="concat('boolean(', $ref, ')')" />
			</xslt:attribute><xsl:value-of select="">
			<xslt:attribute name="select">
				<xslt:value-of select="$ref" />
			</xslt:attribute>
			</xsl:value-of>
		</xsl:when>
		<xsl:otherwise>
		</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<xsl:variable name="url"><xsl:value-of select=""><xslt:attribute name="select"><xslt:value-of select="concat('//',$UcAppName,'/@script')" /></xslt:attribute></xsl:value-of>/json</xsl:variable>
<xslt:variable name="entityName" select="translate(/atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/@Name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>
<xslt:variable name="label">
	<xslt:choose>
		<xslt:when test="not(/atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/@Label) or /atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/@Label=''">
			<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/@Name"/>
		</xslt:when>
		<xslt:otherwise>
			<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/@Label"/>
		</xslt:otherwise>
	</xslt:choose>
</xslt:variable>

<script type="text/javascript">
	require(["dijit/form/Select", "dojo/data/ItemFileReadStore", "dojo/store/JsonRest"],
		function(Select, ItemFileReadStore, JsonRest){
			new JsonRest({target:"<xsl:value-of select="$url" />"})
				.get('/<xslt:value-of select="$entityName" />/').then(function(data){
					var readStore = new ItemFileReadStore({data: {
						identifier: "<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/atns:Key[@AutoUniqueValue='YES']/atns:FieldRef/@Name"/>",
						label: "<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/@Name"/>",
<!-- - - >
						label: "<xslt:call-template name="join">
							<xslt:with-param name="valueList" select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$p_ref_id]/atns:Field[@Hidden!='YES' or not(@Hidden)]/@Name"/>
							<xslt:with-param name="separator" select="'_'"/>
						</xslt:call-template>",
<! - - -->
						items: data.repository.items}
					});
					var select = new Select({
						id: 'id_<xslt:value-of select="@To"/>',
						name: "<xslt:value-of select="@To"/>",
						value: "<xsl:value-of select="$value_ref"/>",
						promptMessage: "Select <xslt:value-of select="$label"/>",
						store: readStore
					}, "id_<xslt:value-of select="@To"/>");
					select.set('style','width: 15em; overflow: hidden;');
					select.startup();
				});
});
</script>

<input id="id_"><xsl:attribute name="id">id_<xslt:value-of select="@To"/></xsl:attribute></input>

</xslt:template>


<xslt:template match="atns:Entity" mode="bind" >
<xslt:variable name="bindId" select="@Id"/>
<xslt:variable name="EId" select="/atns:Application/atns:Entity/@Id"/>
<xslt:variable name="endId" select="/atns:Application/atns:Relations/atns:Relation[@RefId != $EId]/atns:EntityRef[@RefId = $bindId]/../@RefId"/>

<!--bindId=<xslt:value-of select="$bindId"/>
EId=<xslt:value-of select="$EId"/>
endId=<xslt:value-of select="$endId"/>
name1=<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=1]/@Name"/>
name2=<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=2]/@Name"/>
name3=<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=3]/@Name"/>
name4=<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=4]/@Name"/>
name5=<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=5]/@Name"/>
-->
<xsl:variable name="url"><xsl:value-of select=""><xslt:attribute name="select"><xslt:value-of select="concat('//',$UcAppName,'/@script')" /></xslt:attribute></xsl:value-of>/json</xsl:variable>
<xslt:variable name="entityName" select="translate(/atns:Application/atns:EntitysRef/atns:Entity[@Id=$bindId]/@Name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>
<xslt:variable name="label">
	<xslt:choose>
		<xslt:when test="not(/atns:Application/atns:EntitysRef/atns:Entity[@Id=$endId]/@Label) or /atns:Application/atns:EntitysRef/atns:Entity[@Id=$endId]/@Label=''">
			<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$endId]/@Name"/>
		</xslt:when>
		<xslt:otherwise>
			<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$endId]/@Label"/>
		</xslt:otherwise>
	</xslt:choose>
</xslt:variable>
<tr><td><xslt:value-of select="$label"/></td>
	<td>
<script type="text/javascript">
	require(["dijit/form/MultiSelect", "dojo/data/ItemFileReadStore", "dojo/store/JsonRest"],
		function(Select, ItemFileReadStore, JsonRest){
			new JsonRest({target:"<xsl:value-of select="$url" />"})
				.get('/<xslt:value-of select="$entityName" />/').then(function(data){
					var readStore = new ItemFileReadStore({data: {
						identifier: "<xslt:value-of select="/atns:Application/atns:Relations/atns:Relation[@RefId = $endId]/atns:EntityRef[@RefId = $bindId]/@To"/>",
						label: "<xslt:value-of select="/atns:Application/atns:EntitysRef/atns:Entity[@Id=$endId]/@Name"/>",
						items: data.repository.items}
					});
					var select = new Select({
						id: 'id_<xslt:value-of select="/atns:Application/atns:Relations/atns:Relation[@RefId = $endId]/atns:EntityRef[@RefId = $bindId]/@To"/>',
						name: "<xslt:value-of select="/atns:Application/atns:Relations/atns:Relation[@RefId = $endId]/atns:EntityRef[@RefId = $bindId]/@To"/>",
						value: "",
						promptMessage: "Select <xslt:value-of select="$label"/>",
						store: readStore
					}, "id_<xslt:value-of select="/atns:Application/atns:Relations/atns:Relation[@RefId = $endId]/atns:EntityRef[@RefId = $bindId]/@To"/>");
					select.set('style','width: 15em; overflow: hidden;');
					select.startup();
				});
});
</script>

<input id="id_"><xsl:attribute name="id">id_<xslt:value-of select="/atns:Application/atns:Relations/atns:Relation[@RefId = $endId]/atns:EntityRef[@RefId = $bindId]/@To"/></xsl:attribute></input>
	</td></tr>
</xslt:template>


<!-- xslt:template match="atns:Field" mode="relationAttr"><xslt:value-of select="concat($s_q, @Name, $s_q, ':', $s_q, '@', @Name, $s_q)" /><xslt:if test="position()!=last()">,</xslt:if></xslt:template -->

</xslt:stylesheet>