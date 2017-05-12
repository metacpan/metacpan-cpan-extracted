<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="html">

<xsl:output method="xml" indent="yes"/>

<xsl:template match="/">
<html>
  <xsl:apply-templates select="/html:html/html:head"/>
  <body>
    <div>
      <xsl:apply-templates select="//html:div[@id='col2'][1]/*[not(self::html:br|self::html:div[starts-with(@class, 'col-')])]"/>
    </div>
  </body>
</html>
</xsl:template>

<xsl:template match="html:head">
  <head>
    <title><xsl:value-of select="normalize-space(//html:html/html:head/html:title[1])"/></title>
    <xsl:apply-templates select="html:base|html:meta[not(@http-equiv) and not(@name = 'MSSmartTagsPreventParsing' or @name = 'google-site-verification')]|html:link[not(@rel = 'stylesheet' or @rel = 'alternate')]"/>
  </head>
</xsl:template>

<xsl:template match="html:b">
  <strong><xsl:apply-templates/></strong>
</xsl:template>

<xsl:template match="html:i">
  <em><xsl:apply-templates/></em>
</xsl:template>

<xsl:template match="html:tt">
  <code><xsl:apply-templates/></code>
</xsl:template>

<xsl:template match="*">
<xsl:element name="{name()}"> <!-- namespace="{namespace-uri()}">-->
  <xsl:for-each select="@*[not(name() = 'style')]">
    <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
  </xsl:for-each>
  <xsl:apply-templates/>
</xsl:element>
</xsl:template>

</xsl:stylesheet>