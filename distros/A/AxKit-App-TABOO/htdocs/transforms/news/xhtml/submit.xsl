<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ct="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Control"
  xmlns:cust="http://www.kjetil.kjernsmo.net/software/TABOO/NS/CustomGrammar"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  xmlns:str="http://mozref.com/2004/String"
  exclude-result-prefixes="ct cust story user cat rdf wn dc i18n texts str"> 

  <xsl:import href="match-story.xsl"/>
  <xsl:import href="../../../transforms/xhtml/match-control.xsl"/>
  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/>
  <xsl:import href="/transforms/insert-i18n.xsl"/>
  <xsl:import href="/transforms/ends-with.xsl"/>
  <xsl:import href="match-breadcrumbs.xsl"/>

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
      </head>
      <body>      
	<xsl:call-template name="CreateHeader"/>
	<div id="breadcrumb">
	  <xsl:call-template name="BreadcrumbTop"/>
	  <xsl:call-template name="BreadcrumbNews"/>
	  <xsl:if test="str:ends-with($request.uri, '/edit')">
	    <!-- TODO: This won't work if one previews -->
	    <xsl:text> &gt; </xsl:text>
	    <a>
	      <xsl:attribute name="href">
		<xsl:text>/news/</xsl:text>
		<xsl:value-of select="/cust:submit/cat:categories/cat:category/cat:catname"/>
	      </xsl:attribute>
	      <xsl:value-of select="/cust:submit/cat:categories/cat:category/cat:name"/>
	    </a>
	    <xsl:text> &gt; </xsl:text>
	    <!-- link to article without any comments -->
	    <a rel="up" href="{substring-before($request.uri, 'edit')}">
	      <xsl:value-of select="i18n:include('article-no-comments')"/>
	    </a>
	  </xsl:if>
	  <xsl:text> &gt; </xsl:text>
	</div>
	<div id="container">	
	  
	  <h2 class="pagetitle"><xsl:apply-templates select="./cust:title/node()"/></h2>
	  
	  <xsl:variable name="uri" select="concat('http://',
					   substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  
	  <div class="main">
	    
	    <div id="the-story">
	      <xsl:apply-templates select="./story:story-submission/story:story"/>
	    </div>  
	    
	    <xsl:choose>
	      <xsl:when test="//story:store=1">
		<xsl:value-of select="i18n:include('story-stored')"/>
		<p>
		  <xsl:value-of
		      select="i18n:include('editors-will-check')"/> 
		  <xsl:value-of
		      select="i18n:include('return-to-top-page')"/> 
		  <a rel="top" href="/"><xsl:value-of
		  select="document('/site/main.rdf')//dc:title/rdf:Alt/rdf:_1"/>
		  </a>
		</p>
	      </xsl:when>
	      <xsl:otherwise>
		<form method="post" action="/news/submit">
		  <div class="fields">
		    <xsl:apply-templates select="./ct:control"/>
		  </div>
		</form>		
	      </xsl:otherwise>
	    </xsl:choose>
	    
	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>
      </body>      
    </html>
  </xsl:template>
  


</xsl:stylesheet>


