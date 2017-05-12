<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="html" encoding="ISO-8859-1"/>
    <xsl:template match="/">
        <html>
           <head><title>example 2 form</title></head>
           <body>
               <xsl:value-of select="//message"/><br/>
               <form>
               your email: <input name="email" value="{//email}"/><br/>
               <input type="submit" name="submit" value="send!"/><br/>
               </form>
           </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
