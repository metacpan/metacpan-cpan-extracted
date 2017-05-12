<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ct="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Control"
  xmlns:cust="http://www.kjetil.kjernsmo.net/software/TABOO/NS/CustomGrammar"
  xmlns:comm="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  exclude-result-prefixes="ct cust comm user cat rdf wn dc i18n texts"> 

 
  <xsl:import href="match-comment.xsl"/>
  <xsl:import href="../../../transforms/xhtml/match-control.xsl"/>
  <xsl:import href="../../../transforms/xhtml/header.xsl"/>
  <xsl:import href="../../../transforms/xhtml/footer.xsl"/>
  <xsl:import href="../../../transforms/insert-i18n.xsl"/>
  <xsl:import href="match-breadcrumbs.xsl"/>

  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  


  <xsl:param name="request.headers.host"/>
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
	  <xsl:text> &gt; </xsl:text>
	  <a>
	    <xsl:attribute name="href">
	      <xsl:text>/news/</xsl:text>
	      <xsl:value-of select="/cust:submit/cat:categories/cat:category/cat:catname"/>
	    </xsl:attribute>
	    <xsl:value-of select="/cust:submit/cat:categories/cat:category/cat:name"/>
	  </a>
	  <!-- up to here, it is just the crumbs that needs to be there regardless of uri -->
	  <xsl:variable name="url-rest">
	    <xsl:value-of select="substring-after($request.uri, concat('/news/', /cust:submit/cat:categories/cat:category/cat:catname, '/'))"/>
	  </xsl:variable>
	  <xsl:text> &gt; </xsl:text>
	  <!-- link to article without any comments -->
	  <a href="{substring-before($request.uri, 'comment/')}">
	    <xsl:value-of select="i18n:include('article-no-comments')"/>
	  </a>
	  <xsl:text> &gt; </xsl:text>
	  <a>
	    <xsl:attribute name="href">
	      <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
	      <xsl:text>comment/</xsl:text>
	    </xsl:attribute>
	    <xsl:value-of select="i18n:include('just')"/>
	    <xsl:value-of select="i18n:include('list-noun')"/>
	  </a>

	  <!-- TODO: breadcrumbs for commentators -->
	  <!-- xsl:call-template name="BreadcrumbNav">
	    <xsl:with-param name="commentpath">
	      <xsl:value-of select="$after-comment"/>
	    </xsl:with-param>
	    <xsl:with-param name="uri-before">
	      <xsl:value-of select="substring-before($request.uri, '/comment/')"/>
	      <xsl:text>/comment</xsl:text>
	    </xsl:with-param>
	  </xsl:call-template -->
	  
	  <xsl:text> &gt; </xsl:text>
	  

	</div>
	<div id="container">
	  <h2 class="pagetitle"><xsl:apply-templates select="./cust:title/node()"/></h2>
	  
	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  
	  <div class="main">
	    
	    <xsl:apply-templates select="./comm:comment-submission/comm:reply"/>
	    
	    <xsl:if test="//comm:store=1">
	      <xsl:value-of select="i18n:include('comment-stored')"/>
	      <p>
		<xsl:value-of
		  select="i18n:include('return-to-top-page')"/> 
		<a rel="top" href="/">
		  <xsl:value-of select="document('/site/main.rdf')//dc:title/rdf:Alt/rdf:_1"/>
		</a>
		<xsl:value-of select="i18n:include('or')"/>
		<xsl:value-of select="i18n:include('to')"/>
		<a rel="up">
		  <xsl:attribute name="href">
		    <xsl:value-of select="substring-before($request.uri, '/respond')"/>
		    <xsl:text>/thread</xsl:text>
		  </xsl:attribute>
		  <xsl:value-of select="i18n:include('previous')"/>
		  <xsl:value-of select="i18n:include('comment')"/>
		</a>
	      </p>
	    </xsl:if>
	    
	    <form method="post" action="">
	      <div class="fields">
		<xsl:apply-templates select="./ct:control"/>
	      </div>
	    </form>

	    <xsl:if test="./comm:comment-loaded/comm:reply">
	      <div class="reply-to">
		<h2><xsl:value-of select="i18n:include('you-respond-to')"/></h2>
		<xsl:apply-templates select="./comm:comment-loaded/comm:reply"/>
	      </div>
	    </xsl:if>


	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>
      </body>      
    </html>
  </xsl:template>
  
</xsl:stylesheet>
