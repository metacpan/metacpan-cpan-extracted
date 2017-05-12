<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="html"/>
    <xsl:template match="/">
        <html>
           <head><title>example 2 finish</title></head>
           <body>
               <xsl:value-of select="//message"/><br/>
           </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
