<?xml version="1.0"?>
<!-- Produces HTML output for simple pages -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:pod="http://axkit.org/ns/2000/pod2xml">
 <xsl:output method="html"/>
 <xsl:template match="/">
  <html>
   <xsl:apply-templates/>
  </html>
 </xsl:template>
 <xsl:template match="header">
  <head>
   <title>
    <xsl:value-of select="."/> HTML
   </title>
  </head>
 </xsl:template>
 <xsl:template match="body">
  <body>
   <xsl:apply-templates/>
  </body>
 </xsl:template>
 <xsl:template match="para">
  <p>
   <xsl:apply-templates/>
  </p>
 </xsl:template>
 <xsl:template match="MODEL_VAR">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:copy>
 </xsl:template>
</xsl:stylesheet>
