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
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<title><xslt:value-of select="/atns:Application/@Label"/></title>
		<xslt:apply-imports/>

		<script type="text/javascript">
			require(["dijit/layout/ContentPane", "dijit/layout/BorderContainer", "dijit/layout/AccordionContainer", "dojo/parser"]);
		</script>

		<style type="text/css">
			#appLayout {
				height: 95%;
			}
			#leftCol {
				width: 16em;
			}
			.head {
				background-color: #80ccff;
				font-size: 1.5em;
				height: 1.6em;
			}

			.claro .demoLayout .edgePanel {
				//background-color: #d0e9fc;
			}

			a {color:#408DD2;}
		</style>
	</head>

	<body class="claro">
		<div class="head">
			<xsl:text disable-output-escaping="yes">&amp;nbsp;&amp;nbsp;</xsl:text><b><xslt:value-of select="/atns:Application/@Label"/></b>
		</div>
		<div id="appLayout" class="demoLayout" data-dojo-type="dijit.layout.BorderContainer" data-dojo-props="design: 'headline'">
			<div id="leftCol" class="leftCol" data-dojo-type="dijit.layout.ContentPane" data-dojo-props="region: 'left', splitter: true"><div style="width: 100%;height:50%;">
				<xslt:apply-templates select="/atns:Application/atns:MenuGroups" />
				<a>
					<xsl:attribute name="href">
						<xsl:value-of>
							<xslt:attribute name="select"><xslt:value-of select="concat('concat(', $UcAppName, '/@script', ',', $s_q, '/?action=/exit', $s_q, ')')" /></xslt:attribute>
						</xsl:value-of>
					</xsl:attribute>Logout</a><br />
			</div></div>
			<div class="centerPanel" data-dojo-type="dijit.layout.ContentPane" data-dojo-props="region: 'center'">
				<iframe name="mainFrame" style="width:100%; height:99%; border:0px;"></iframe>
			</div>
		</div>
	</body>
</html>

</xsl:template>
</xsl:stylesheet>

</xslt:template>

<xslt:template match="/atns:Application/atns:MenuGroups">
<div dojoType="dijit.layout.AccordionContainer" style="height: 300px;">
	<xslt:apply-templates select="atns:Group" />
</div>
</xslt:template>

<xslt:template match="atns:Group">
<div data-dojo-type="dijit.layout.ContentPane">
	<xslt:attribute name="title"><xslt:value-of select="@Title" /></xslt:attribute>
	<xslt:apply-templates select="atns:EntityRef" />
</div>
</xslt:template>

<xslt:template match="atns:EntityRef">
	<xslt:variable name="refId" select="@RefId"/>
	<xslt:variable name="entityName" select="translate(//atns:Entitys/atns:Entity[@Id=$refId]/@Name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>

	<xslt:variable name="entityLabel">
		<xslt:choose>
			<xslt:when test="//atns:Entitys/atns:Entity[@Id=$refId]/@Label!=''"><xslt:value-of select="//atns:Entitys/atns:Entity[@Id=$refId]/@Label" /></xslt:when>
			<xslt:otherwise><xslt:value-of select="//atns:Entitys/atns:Entity[@Id=$refId]/@Name" /></xslt:otherwise>
		</xslt:choose>
	</xslt:variable>

	<xslt:variable name="entityType" select="//atns:Entitys/atns:Entity[@Id=$refId]/@Type" />

	<xslt:if test="$entityType='TABLE'">
	<a target="mainFrame">
		<xsl:attribute name="href">
			<xsl:value-of>
				<xslt:attribute name="select"><xslt:value-of select="concat('concat(', $UcAppName, '/@script', ',', $s_q, '/', $entityName, '/-1', $s_q, ')')" /></xslt:attribute>
			</xsl:value-of>
		</xsl:attribute>Add new <xslt:value-of select="$entityLabel" /></a><br />
	</xslt:if>
	<xslt:if test="$entityType!='ABSTRACT' and $entityType!='BIND' and $entityType!='TREE'">
	<a target="mainFrame">
		<xsl:attribute name="href">
			<xsl:value-of>
				<xslt:attribute name="select"><xslt:value-of select="concat('concat(', $UcAppName, '/@script', ',', $s_q, '/', '?action=/list&amp;entity=',$RealAppName, '::Entity::', @Type,$s_q, ')')" /></xslt:attribute>
			</xsl:value-of>
		</xsl:attribute>List of <xslt:value-of select="$entityLabel" /></a><br />
	</xslt:if>
	<xslt:if test="$entityType='TREE'">
	<a target="mainFrame">
		<xsl:attribute name="href">
			<xsl:value-of>
				<xslt:attribute name="select"><xslt:value-of select="concat('concat(', $UcAppName, '/@script', ',', $s_q, '/', '?action=/tree&amp;entity=',$RealAppName, '::Entity::', @Type,$s_q, ')')" /></xslt:attribute>
			</xsl:value-of>
		</xsl:attribute><xslt:value-of select="$entityLabel" /></a><br />
	</xslt:if>
</xslt:template>

</xslt:stylesheet>
