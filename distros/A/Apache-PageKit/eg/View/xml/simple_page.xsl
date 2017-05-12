<?xml version="1.0"?>
<!-- Produces XML output for simple pages -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 <xsl:template match="header">
  <header><xsl:value-of select="."/> XML</header>
 </xsl:template>
 <xsl:template match="page|body|para|MODEL_VAR">
  <xsl:copy>
   <xsl:copy-of select="@*"/>
   <xsl:apply-templates/>
  </xsl:copy>
 </xsl:template>
</xsl:stylesheet>
