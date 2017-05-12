<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:art="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  xmlns:office="http://openoffice.org/2000/office" 
  xmlns:type="http://www.kjetil.kjernsmo.net/software/TABOO/NS/MediaType/Output"  
  exclude-result-prefixes="office art i18n texts html type"> 
	    
  <xsl:import href="oo2html.xsl"/>

  <xsl:template name="ArticleContent">
    <div id="content">
      <xsl:choose>
	<xsl:when test="art:article/type:mediatype/type:mimetype = 'application/xhtml+xml'">
	  <xsl:if test="not($content/html:html/html:body/html:h1)">
	    <h1><xsl:value-of select="./art:title"/></h1>
	  </xsl:if>
	  <xsl:copy-of select="$content/html:html/html:body/child::*"/>
	</xsl:when>
	<xsl:when test="art:article/type:mediatype/type:mimetype = 'application/vnd.sun.xml.writer'">
	  <xsl:apply-templates select="$content/office:document-content/office:body"/>
	</xsl:when>
	<xsl:when test="not($content/html/body)">
	  <xsl:copy-of select="$content"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:if test="not($content/html/body/h1)">
	    <h1><xsl:value-of select="./art:title"/></h1>
	  </xsl:if>
	  <xsl:copy-of select="$content/html/body/child::*"/>
	</xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>
</xsl:stylesheet>