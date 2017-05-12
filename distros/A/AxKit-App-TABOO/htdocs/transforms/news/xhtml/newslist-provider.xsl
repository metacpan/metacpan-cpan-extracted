<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  xmlns:str="http://mozref.com/2004/String"
  exclude-result-prefixes="user story cat rdf wn dc i18n texts str"> 

  <xsl:import href="/transforms/insert-i18n.xsl"/>
  <xsl:import href="/transforms/news/xhtml/match-story.xsl"/>
  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="/transforms/xhtml/rightsidebar.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/> 
  <xsl:import href="match-breadcrumbs.xsl"/>
  

  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  

  <xsl:param name="request.headers.host"/>
  <xsl:param name="request.uri"/>
  <xsl:param name="session.id"/>
  <xsl:param name="neg.lang">en</xsl:param>


  <xsl:template match="/">
    <html lang="{$neg.lang}">
      <head>
	<title>
	  <xsl:choose>
	    <xsl:when test="taboo/cat:category/cat:type='stsec'">
	      <xsl:value-of select="taboo/cat:category/cat:name"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="i18n:include('listing-everything')"/>
	    </xsl:otherwise>
	  </xsl:choose>
	  <xsl:text> | </xsl:text>
	  <xsl:value-of select="document('/site/main.rdf')//dc:title/rdf:Alt/rdf:_2"/>
	</title>
	<xsl:call-template name="CommonHTMLHead"/>
	<link rel="up" href=".."/>
	<link rel="top" href="/"/>
      </head>
      <body> 
	<xsl:call-template name="CreateHeader"/>
	<div id="breadcrumb">
	  <xsl:call-template name="BreadcrumbTop"/>
	  <xsl:call-template name="BreadcrumbParseUri">
	    <xsl:with-param name="path" select="concat(substring-after($request.uri, '/news/'), '/')"/>
	  </xsl:call-template>
	  <xsl:text> &gt; </xsl:text>
	</div>

	<div id="container">
	  <h2 id="sectionhead">
	    <xsl:choose>
	      <xsl:when test="taboo/cat:category/cat:type='stsec'">
		<xsl:value-of select="taboo/cat:category/cat:name"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:value-of select="i18n:include('listing-everything')"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </h2>
	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  <xsl:call-template name="CreateRightSidebar"/>
	  <div class="main">
	    <xsl:choose>
	      <xsl:when test="taboo[@type='list']">
		<table>	
		  <thead>
		    <tr>
		      <th scope="col">
			<xsl:value-of select="i18n:include('article-title')"/>
		      </th>
		      <th scope="col">
			<xsl:value-of select="i18n:include('submitter')"/>
		      </th>
		      <th scope="col">
			<xsl:value-of select="i18n:include('primcat')"/>
		      </th>
		      <th scope="col">
			<xsl:value-of select="i18n:include('on-time')"/>
		      </th>
		    </tr>
		  </thead>
		  <tbody>
		    <xsl:apply-templates select="/taboo/story:story"/>
		  </tbody>
		</table>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:apply-templates select="/taboo/story:story"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>
      </body>
    </html>
  </xsl:template>


  <xsl:template name="BreadcrumbParseUri">
    <xsl:param name="path"/>
    <xsl:param name="current"/>
    <xsl:choose>
      <xsl:when test="substring-before($path, '/') = /taboo/cat:category/cat:catname">  
	<xsl:call-template name="BreadcrumbNews"/>
	<xsl:call-template name="BreadcrumbParseUri">
	  <xsl:with-param name="path" select="substring-after($path, '/')"/>
	  <xsl:with-param name="current" select="'sectionid'"/>
	</xsl:call-template>

      </xsl:when>
      <xsl:when test="substring-before($path, '/') = 'editor' or substring-before($path, '/') = 'unpriv'">
	<xsl:choose> 
	  <xsl:when test="$current ='sectionid'">
	    <xsl:call-template name="BreadcrumbSection"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:call-template name="BreadcrumbNews"/>
	  </xsl:otherwise>
	</xsl:choose>
	<xsl:call-template name="BreadcrumbParseUri">
	  <xsl:with-param name="path" select="substring-after($path, '/')"/>
	  <xsl:with-param name="current" select="substring-before($path, '/')"/>
	</xsl:call-template>

      </xsl:when>
      <xsl:when test="substring-before($path, '/') = 'list'">
	<xsl:text> &gt; </xsl:text>
	<a rel="up" href="{substring-before($request.uri, '/list')}">
	  <xsl:value-of select="i18n:include('overview')"/>
	</a>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
    

</xsl:stylesheet>
