<?xml version="1.0" encoding="UTF-8" ?>
<xslt:stylesheet version="1.0" 
	xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/TransformAlias"
	xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xslt:import href="incDojo_JS_Css.xsl" />

<xslt:output method="xml" indent="yes" />
<xslt:namespace-alias stylesheet-prefix="xsl" result-prefix="xslt"/>

<xslt:include href="../../incName.xsl" />

<xslt:template match="/">

<xsl:stylesheet version="1.0">

<xsl:output method="html" indent="yes" />

<xsl:template match="/"><xsl:text disable-output-escaping="yes">&lt;!DOCTYPE HTML>
</xsl:text>
<html lang="en">
	<xslt:if test="boolean(/Application/@Language)">
		<xslt:attribute name="lang">
			<xslt:value-of select="/Application/@Language"/>
		</xslt:attribute>
	</xslt:if>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
		<xslt:apply-imports/>
		<script type="text/javascript">
				require(["dijit/dijit","dijit/form/Form","dijit/form/Button","dijit/form/ValidationTextBox","dojo/domReady!","dojo/parser"]);
		</script>
	</head>
	<body class="claro">
		<xsl:apply-templates select="//repository/mng_EWM"/>
		<xsl:apply-templates>
			<xslt:attribute name="select"><xslt:value-of select="$UcAppName" /></xslt:attribute>
		</xsl:apply-templates>
	</body>
</html>
</xsl:template>
<xsl:template>
	<xslt:attribute name="match"><xslt:value-of select="$UcAppName" /></xslt:attribute>
	<xslt:variable name="entityName" select="translate(/atns:Application/atns:Entitys/atns:Entity/@Name[1], $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>
	<form method="POST">
		<xsl:attribute name="action"><xsl:value-of select="@script" />/</xsl:attribute>
		<xsl:apply-templates select="repository"/>
		<button data-dojo-type="dijit.form.Button" data-dojo-props="type:'submit', value:'Submit'">Submit</button>
	</form>
</xsl:template>

<xsl:template match="repository">
<table>
	<tr>
		<td>Username</td>
		<td>
			<xsl:variable name="value">,value:"<xsl:value-of select="./SysUser/@login"/>"</xsl:variable>
			<input data-dojo-type="dijit.form.ValidationTextBox">
				<xsl:attribute name="data-dojo-props">
					<xsl:value-of select="concat('id:&quot;id_Login&quot;,name:&quot;login&quot;,type:&quot;text&quot;,trim:true,maxLength:&quot;32&quot;,promptMessage:&quot;Login&quot;',$value)"/>
				</xsl:attribute>
			</input>
		</td>
	</tr>
	<tr>
		<td>Password</td>
		<td>
			<xsl:variable name="value">,value:"<xsl:value-of select="./SysUser/@pswd"/>"</xsl:variable>
			<input data-dojo-type="dijit.form.ValidationTextBox">
			<xsl:attribute name="data-dojo-props">
				<xsl:value-of select="concat('id:&quot;id_Password&quot;,name:&quot;password&quot;,type:&quot;password&quot;,trim:true,maxLength:&quot;32&quot;,promptMessage:&quot;Password&quot;',$value)"/>
			</xsl:attribute>
		  </input>
		</td>
	</tr>
</table>
</xsl:template>
</xsl:stylesheet>

</xslt:template>

</xslt:stylesheet>