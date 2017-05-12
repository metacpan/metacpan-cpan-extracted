<?xml version = "1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:param name="source" select="'chado'"/>
  <xsl:output indent="yes" method="text" />

  <xsl:strip-space elements="*"/>
  
  <xsl:template match="/chaos">
    <xsl:apply-templates match="feature_relationship"/>
  </xsl:template>

  <xsl:template match="featureprop" mode="score">
  </xsl:template>

  <xsl:template match="feature_relationship">
    <xsl:value-of select="subject_id"/>
    <xsl:text>&#9;</xsl:text>
    <xsl:value-of select="object_id"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="text()|@*">
  </xsl:template>


</xsl:stylesheet>
