<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:art="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  xmlns:office="http://openoffice.org/2000/office" 
  exclude-result-prefixes="office cat user art rdf wn dc i18n texts html"> 


  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/>
  <xsl:import href="/transforms/insert-i18n.xsl"/>
  <xsl:import href="match-content.xsl"/>
  <xsl:import href="match-author.xsl"/>
  <xsl:import href="/transforms/news/xhtml/match-breadcrumbs.xsl"/>

  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  

  <xsl:param name="request.headers.host"/>
  <xsl:param name="request.uri"/>
  <xsl:param name="session.id"/>
  <xsl:param name="neg.lang">en</xsl:param>
  <xsl:variable name="content"/>

  <xsl:template match="/taboo/taboo">
    <xsl:apply-templates select="art:article">
      <xsl:with-param name="content" select="document(@contenturl)"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="art:article">
    <xsl:param name="content"/>
    <html lang="{$neg.lang}">
      <head>
	<title>
	  <xsl:value-of select="./art:title"/>
	  
	  <xsl:text> | </xsl:text>
	  <xsl:value-of select="document('/site/main.rdf')//dc:title/rdf:Alt/rdf:_2"/>
	</title>
	<xsl:call-template name="CommonHTMLHead"/>
	<link rel="top" href="/"/>
      </head>
      <body>
	<xsl:call-template name="CreateHeader"/>
	<div id="breadcrumb">
	  <xsl:call-template name="BreadcrumbTop"/>
	  <xsl:text> &gt; </xsl:text>
	  <a href="{concat($cats.prefix, ./cat:primcat/cat:catname)}">
	    <xsl:value-of select="./cat:primcat/cat:name"/>
	  </a>
	  <xsl:text> &gt; </xsl:text>
	</div> 
	<div id="container">
	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  <div class="main">

	    <h2 id="byline">
	      <xsl:call-template name="ArticleAuthors"/>
	    </h2>
	    
	    <xsl:call-template name="ArticleContent">
	      <xsl:with-param name="content" select="$content"/>
	    </xsl:call-template>

	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>

      </body>
    </html>
  </xsl:template>


</xsl:stylesheet>