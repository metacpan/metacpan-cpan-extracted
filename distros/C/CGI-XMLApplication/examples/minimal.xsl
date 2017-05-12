<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/TR/xhtml1/strict">
<!-- $Id -->
<xsl:param name="version"/>
<xsl:output method="html" encoding="ISO-8859-1"/>
<xsl:template match="/">
<html>
  <head>
    <title>
    evaluate! userlisting
    </title>
  </head>
  <body bgcolor="ffffff">

    <h1>CGI::XMLApplication</h1>
    <p> 
The Version of CGI::XMLApplication is <xsl:value-of select="$version"/>
    </p>
  </body>
</html>
</xsl:template>


</xsl:stylesheet>
