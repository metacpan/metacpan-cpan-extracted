<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:art="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  xmlns:str="http://mozref.com/2004/String"
  exclude-result-prefixes="user art story cat rdf wn dc i18n texts str"> 

  <xsl:import href="/transforms/insert-i18n.xsl"/>
  <xsl:import href="/transforms/news/xhtml/match-story.xsl"/>
  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="/transforms/xhtml/rightsidebar.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/> 
  <xsl:import href="/transforms/news/xhtml/match-breadcrumbs.xsl"/>
  <xsl:import href="/transforms/articles/xhtml/match-metadata.xsl"/>


  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  

  <xsl:param name="request.headers.host"/>
  <xsl:param name="request.uri"/>
  <xsl:param name="session.id"/>
  <xsl:param name="neg.lang">en</xsl:param>
  <xsl:param name="cats.prefix"/>


  <xsl:template match="/">
    <html lang="{$neg.lang}">
      <head>
	<title>
	  <xsl:for-each select="/taboo/cat:category">
	    <xsl:value-of select="./cat:name"/>
	    <xsl:choose>
	      <xsl:when test="position()=last()">
	      </xsl:when>
	      <xsl:when test="position()=last()-1">
		<xsl:value-of select="i18n:include('and')"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:text>, </xsl:text>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
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
	  <xsl:text> &gt; </xsl:text>
	  <xsl:for-each select="/taboo/cat:category">
	    <xsl:if test="position() &gt; 1"><!-- TODO: works only for a single subcat -->
	      <a href="{concat($cats.prefix, preceding-sibling::cat:category[1]/cat:catname)}">
		<xsl:value-of select="preceding-sibling::cat:category[1]/cat:name"/>
	      </a>
	      <xsl:text> &gt; </xsl:text>
	    </xsl:if>
	  </xsl:for-each>
	  
	</div>

	<div id="container">
	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  <xsl:call-template name="CreateRightSidebar"/>

	  <div class="main">

	    <div class="foundcats">
	      <xsl:for-each select="/taboo/cat:category">
		<h2><xsl:value-of select="./cat:name"/></h2>
		<p class="description">
		  <xsl:value-of select="./cat:description"/>
		</p>
	      </xsl:for-each>
	    </div>

	    <dl class="articlelist">
	      <xsl:for-each select="/taboo/art:article">
		<xsl:apply-templates select="."/>
	      </xsl:for-each>
	    </dl>

	    <xsl:if test="/taboo/story:story">
	      <table>
		<caption><xsl:value-of select="i18n:include('stories-title-menu')"/></caption>
		<thead>
		  <tr>
		    <th scope="col">
		      <xsl:value-of select="i18n:include('article-title')"/>
		    </th>
		    <th scope="col">
		      <xsl:value-of select="i18n:include('submitter')"/>
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
	    </xsl:if>


	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>