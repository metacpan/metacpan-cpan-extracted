<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:func="http://exslt.org/functions"
		xmlns:str="http://mozref.com/2004/String"
		extension-element-prefixes="func str"
		exclude-result-prefixes="func str">
  
  <!-- Many thanks to Mike Nachbaur for putting this together -->
  
  <func:function name="str:ends-with">
    <xsl:param name="source"/>
    <xsl:param name="find"/>
    <xsl:choose>
      <xsl:when test="contains($source, $find) and 
		      not(substring-after($source, $find))">
	<func:result select="true()"/>
      </xsl:when>
      <xsl:otherwise>
	<func:result select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
</xsl:stylesheet>