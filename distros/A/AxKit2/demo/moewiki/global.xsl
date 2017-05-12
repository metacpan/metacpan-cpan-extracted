<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html"/>

<xsl:template match="/">
<html>
  <head>
    <title>MoeWiki - nothing is smaller</title>
  </head>
  <body>
    <xsl:copy-of select="/html/body/*|/html/body/text()"/>
    <xsl:if test="not(/html/body/form)"><div><a href="?edit">Edit this page</a></div></xsl:if>
  </body>
</html>
</xsl:template>

</xsl:stylesheet>
