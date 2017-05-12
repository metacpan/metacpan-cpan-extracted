<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:cust="http://www.kjetil.kjernsmo.net/software/TABOO/NS/CustomGrammar"
  xmlns:ct="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Control"
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
  exclude-result-prefixes="office user art cat rdf wn dc i18n texts html cust ct"> 


  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/>
  <xsl:import href="/transforms/insert-i18n.xsl"/>
  <xsl:import href="match-content.xsl"/>
  <xsl:import href="match-author.xsl"/>
  <xsl:import href="/transforms/news/xhtml/match-breadcrumbs.xsl"/>
  <xsl:import href="/transforms/xhtml/match-control.xsl"/>

  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  

  <xsl:param name="request.headers.host"/>
  <xsl:param name="request.uri"/>
  <xsl:param name="session.id"/>
  <xsl:param name="neg.lang">en</xsl:param>


  <xsl:template match="cust:submit">
    <html lang="{$neg.lang}">
      <head>
	<title>
	  <xsl:apply-templates select="./cust:title/node()"/>
	  <xsl:text> | </xsl:text>
	  <xsl:value-of select="document('/site/main.rdf')//dc:title/rdf:Alt/rdf:_2"/>
	</title>
	<xsl:call-template name="CommonHTMLHead"/>
	<xsl:call-template name="TinyMCE"/>	
	<link rel="top" href="/"/>
      </head>
      <body>
	<xsl:call-template name="CreateHeader"/>
	<div id="breadcrumb">
	  <xsl:call-template name="BreadcrumbTop"/>
	</div>
	<div id="container">
	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  <div class="main">
	    <h2 class="pagetitle"><xsl:apply-templates select="./cust:title/node()"/></h2>

	    <xsl:apply-templates select="./art:article-submission"/>
	    
	    <xsl:if test="art:problem">
	      <div class="error">
		<h2><xsl:value-of select="i18n:include('problem-occured')"/></h2> 	
		<p>
		  <xsl:for-each select="art:problem">
		    <xsl:choose>
		      <xsl:when test=". = 'title'">
			<xsl:value-of select="i18n:include('article-title')"/>
			<xsl:value-of select="i18n:include('missing')"/>
		      </xsl:when>
		      <xsl:when test=". = 'authorid'">
			<xsl:value-of select="i18n:include('authorid')"/>
			<xsl:value-of select="i18n:include('missing')"/>
		      </xsl:when>
		      <xsl:when test=". = 'description'">
			<xsl:value-of select="i18n:include('article-description')"/>
			<xsl:value-of select="i18n:include('missing')"/>
		      </xsl:when>
		      <xsl:when test=". = 'primcat'">
			<xsl:value-of select="i18n:include('primcat')"/>
			<xsl:value-of select="i18n:include('missing')"/>
		      </xsl:when>
		      <xsl:when test=". = 'code'">
			<xsl:value-of select="i18n:include('language')"/>
			<xsl:value-of select="i18n:include('missing')"/>
		      </xsl:when>
		      <xsl:when test=". = 'text'">
			<xsl:value-of select="i18n:include('article-textstring')"/>
			<xsl:value-of select="i18n:include('missing')"/>
		      </xsl:when>
		      <xsl:when test=". = 'filename' or . = 'upfile'">
			<xsl:value-of select="i18n:include('either-upload-or-filename')"/>
			
		      </xsl:when>
		      <xsl:when test=". = 'nosave'">
			<xsl:value-of select="i18n:include('nosave-problem')"/>
		      </xsl:when>
		      <xsl:otherwise>
			<xsl:value-of select="i18n:include('unknown-problem')"/>
		      </xsl:otherwise>
		    </xsl:choose>
		    <xsl:text>.</xsl:text>
		  </xsl:for-each>
		</p>
	      </div>
	    </xsl:if>
	    
	    <form method="post" enctype="multipart/form-data" action="/articles/submit">
	      <div class="fields">
		<xsl:apply-templates select="./ct:control"/>
	      </div>
	    </form>
	    

	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>

      </body>
    </html>
  </xsl:template>

  <xsl:template match="art:article-submission">
    <h3 id="byline">
      <xsl:call-template name="ArticleAuthors"/>
    </h3>

    <xsl:value-of select="@contenturl"/>

    <!-- xsl:call-template name="ArticleContent">
	 <xsl:with-param name="content" select="document(@contenturl)"/>
	 </xsl:call-template -->


  </xsl:template>


</xsl:stylesheet>