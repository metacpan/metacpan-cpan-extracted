<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="/">
    <content>
      <xsl:apply-templates/>
    </content>
  </xsl:template>

  <xsl:template match="NAV_TITLE">
    <pkit_nav_title>
      <xsl:if test="@pkit_workaround_xml_lang">
	<xsl:attribute name="xml:lang">
	  <xsl:value-of select="@pkit_workaround_xml_lang"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="."/>
    </pkit_nav_title>
  </xsl:template>

  <xsl:template match="CONTENT_LOOP">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="CONTENT_ITEM">
    <xsl:element name="{../@NAME}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="CONTENT_VAR">
    <xsl:element name="{@NAME}">
      <xsl:if test="@pkit_workaround_xml_lang">
	<xsl:attribute name="xml:lang">
	  <xsl:value-of select="@pkit_workaround_xml_lang"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
