<?xml version="1.0"?> 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:template match="hello">
Hello <xsl:apply-templates/>
</xsl:template>

<xsl:template match="page">
  <% $Response->Include('header.inc'); %>
   <xsl:apply-templates/> 
  </body>
  </html>
</xsl:template>

<xsl:template match="title">
 <h2>
  <xsl:apply-templates/>
 </h2>
</xsl:template>

<xsl:template match="paragraph">
 <p>
  <xsl:apply-templates/>
 </p>
</xsl:template> 


<xsl:template match="file">
  <a><xsl:attribute name="href">
       source.asp?file=<xsl:value-of select="@src"/>
     </xsl:attribute><xsl:value-of select="@title"/></a>
</xsl:template>

</xsl:stylesheet>

