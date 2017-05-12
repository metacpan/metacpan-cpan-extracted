<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  exclude-result-prefixes="user story cat i18n rdf rdfs wn dc"> 
  
  <xsl:import href="/transforms/news/xhtml/match-story.xsl"/>
  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="/transforms/xhtml/rightsidebar.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/>

  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  
  
  <xsl:param name="session.id"/>
  <xsl:param name="request.headers.host"/>
  <xsl:param name="neg.lang">en</xsl:param>
  <xsl:param name="cats.prefix"/>

  <xsl:template match="/">
    <html lang="{$neg.lang}">
      <head>
	<title>
	  <xsl:value-of select="document('/site/main.rdf')//dc:title/rdf:Alt/rdf:_1"/>
	</title>
	<xsl:call-template name="CommonHTMLHead"/>
	
      </head>
      <body>
	<xsl:call-template name="CreateHeader"/>
	<div id="container">
	  <h2>
	    <xsl:if test="/taboo/taboo/cat:category/cat:type='stsec'">
	      <xsl:value-of select="/taboo/taboo/cat:category/cat:name"/>
	    </xsl:if>
	  </h2>
	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  <xsl:call-template name="CreateRightSidebar"/>
	  <div class="catlist">
	    <h2><xsl:value-of select="i18n:include('categorized-content')"/></h2>
	    <xsl:apply-templates select="/taboo/cat:categories"/>
	  </div>
	  <div class="main">
	    <xsl:choose>
	      <xsl:when test="/taboo/taboo[@type='list']">
		<table>
		  <xsl:apply-templates select="/taboo/taboo/story:story"/>
		</table>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:apply-templates select="/taboo/taboo/story:story"/>
	      </xsl:otherwise>
	    </xsl:choose>

	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>
      </body>
    </html>
  </xsl:template>


  <xsl:template match="cat:categories">
    <xsl:for-each select="cat:category">
      <div class="categorylink">
	<a href="{concat('http://', substring-before($request.headers.host, ':'), $cats.prefix, ./cat:catname)}">
	  <xsl:value-of select="./cat:name"/>
	</a>
      </div>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>



