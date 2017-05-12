<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  exclude-result-prefixes="user story cat i18n texts"> 

  <xsl:template name="BreadcrumbTop">
    <a rel="top" href="/">
      <xsl:value-of select="i18n:include('top')"/>
    </a>
  </xsl:template>


   <xsl:template name="BreadcrumbNews">
   <xsl:text> &gt; </xsl:text>
    <a href="/news/">
      <xsl:value-of select="i18n:include('stories-title-menu')"/>
    </a>
  </xsl:template>

  <xsl:template name="BreadcrumbSection">
    <xsl:text> &gt; </xsl:text>
    <a>
      <xsl:attribute name="href">
	<xsl:text>/news/</xsl:text>
	<xsl:value-of select="/taboo/story:story/story:sectionid"/>
      </xsl:attribute>
      <xsl:value-of select="/taboo/cat:category/cat:name"/>
    </a>
  </xsl:template>




</xsl:stylesheet>