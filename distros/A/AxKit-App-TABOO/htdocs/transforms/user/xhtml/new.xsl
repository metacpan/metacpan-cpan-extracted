<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:ct="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Control"
  xmlns:cust="http://www.kjetil.kjernsmo.net/software/TABOO/NS/CustomGrammar"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  exclude-result-prefixes="user ct cust rdf wn i18n dc"> 
  <xsl:import href="match-user.xsl"/>
  <xsl:import href="/transforms/insert-i18n.xsl"/>
  <xsl:import href="/transforms/xhtml/match-control.xsl"/>
  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/>
  <xsl:import href="/transforms/news/xhtml/match-breadcrumbs.xsl"/>

  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  
  
  <xsl:param name="request.headers.host"/>
  <xsl:param name="session.id"/>
  <xsl:param name="neg.lang">en</xsl:param>

  <xsl:template match="cust:user">
    <html lang="{$neg.lang}">
      <head>
	<title>
	  <xsl:apply-templates select="./cust:title/node()"/>
	  <xsl:text> | </xsl:text>
	  <xsl:value-of
	  select="document('/site/main.rdf')//dc:title/rdf:Alt/rdf:_2"/>
	</title>
	<xsl:call-template name="CommonHTMLHead"/>
      </head>
      <body>      
	<xsl:call-template name="CreateHeader"/>
	<div id="breadcrumb">
	  <xsl:call-template name="BreadcrumbTop"/>
	  <xsl:text> &gt; </xsl:text>
	</div>
	<div id="container">
	  <h2 class="pagetitle"><xsl:apply-templates select="./cust:title/node()"/></h2>

	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  
	  <div class="main">
	    <xsl:apply-templates select="//user:user"/>
	    
	    <form method="post" action="/user/submit/new">
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
</xsl:stylesheet>

