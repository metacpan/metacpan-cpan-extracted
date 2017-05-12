<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  exclude-result-prefixes="user"> 

  <xsl:template match="user:user|user:submitter">
    <a>
      <xsl:attribute name="href">
	<xsl:text>/user/</xsl:text><xsl:value-of
	select="user:username"/>
      </xsl:attribute>
      <xsl:value-of select="user:name"/>
    </a>
  </xsl:template>

</xsl:stylesheet>