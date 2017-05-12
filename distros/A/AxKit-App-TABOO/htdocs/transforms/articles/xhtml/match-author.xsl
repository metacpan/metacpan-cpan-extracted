<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:art="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  exclude-result-prefixes="user art i18n texts"> 

  <xsl:template name="ArticleAuthors">
    <xsl:for-each select="user:author">
      <span class="authorname">  
	<a>
	  <xsl:attribute name="href">
	    <xsl:text>/user/</xsl:text><xsl:value-of
	    select="./user:username"/>
	  </xsl:attribute>
	  <xsl:value-of select="./user:name" />
	</a>
      </span>
      <xsl:choose>
	<xsl:when test="position()=last()">
	  <xsl:text>:</xsl:text>
	</xsl:when>
	<xsl:when test="position()=last()-1">
	  <xsl:value-of select="i18n:include('and')"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:text>, </xsl:text>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>