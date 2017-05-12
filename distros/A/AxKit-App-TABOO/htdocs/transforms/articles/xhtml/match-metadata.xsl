<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:art="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  exclude-result-prefixes="user cat art i18n texts"> 

  <xsl:import href="/transforms/articles/xhtml/match-author.xsl"/>
  
  <xsl:param name="request.uri"/>
  <xsl:param name="cats.prefix"/>

  <xsl:template match="art:article">
    <dt>
      <a class="article-title">
	<xsl:attribute name="href">
	  <xsl:text>/articles/</xsl:text>
	  <xsl:value-of select="./cat:primcat/cat:catname"/>
	  <xsl:text>/</xsl:text>
	  <xsl:value-of select="./art:filename"/>
	</xsl:attribute>
	<xsl:value-of select="./art:title"/>
      </a>
      <span class="byline">
	<xsl:value-of select="i18n:include('by')"/>
	<xsl:call-template name="ArticleAuthors"/>
      </span>
    </dt>
    <dd>
      <div class="catinfo">
	<xsl:value-of select="i18n:include('cats-title-menu')"/>
	<xsl:text>: </xsl:text>  
	<xsl:for-each select="./cat:*">
	  <a>	
	    <xsl:attribute name="href">
	      <xsl:variable name="catname" select="./cat:catname"/>
	      <xsl:choose> 
		<xsl:when test="contains(substring-after($request.uri, $cats.prefix), $catname)">
		  <xsl:value-of select="$cats.prefix"/>
		  <xsl:value-of select="$catname"/>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:value-of select="$request.uri"/>
		  <xsl:text>/</xsl:text>  
		  <xsl:value-of select="$catname"/>
		</xsl:otherwise>
	      </xsl:choose>
	    </xsl:attribute>
	    <xsl:value-of select="./cat:name"/>
	  </a>
	  <xsl:text>, </xsl:text>  
	</xsl:for-each>

      </div>
      <p class="description">
      	<xsl:value-of select="./art:description"/>
      </p>
    </dd>
  </xsl:template>
</xsl:stylesheet>