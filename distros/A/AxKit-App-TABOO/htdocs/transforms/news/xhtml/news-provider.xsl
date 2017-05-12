<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:comm="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:wn="http://xmlns.com/wordnet/1.6/"      
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  exclude-result-prefixes="user comm story cat rdf wn dc i18n texts"> 

  <xsl:import href="match-story.xsl"/>
  <xsl:import href="match-comment.xsl"/>
  <xsl:import href="/transforms/xhtml/header.xsl"/>
  <xsl:import href="match-breadcrumbs.xsl"/>
  <xsl:import href="/transforms/xhtml/rightsidebar.xsl"/>
  <xsl:import href="/transforms/xhtml/footer.xsl"/>

  <xsl:output version="1.0" encoding="utf-8" indent="yes"
    method="html" media-type="text/html" 
    doctype-public="-//W3C//DTD HTML 4.01//EN" 
    doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>  

  <xsl:param name="request.headers.host"/>
  <xsl:param name="request.uri"/>
  <xsl:param name="session.id"/>
  <xsl:param name="neg.lang">en</xsl:param>

  <xsl:template match="/taboo">
    <html lang="{$neg.lang}">
      <head>
	<title>
	  <xsl:choose>
	    <xsl:when test="@commentstatus = 'threadonly'">
	      <xsl:value-of select="i18n:include('comments')"/>
	      <xsl:value-of select="i18n:include('to')"/>
	    </xsl:when>
	    <xsl:when test="@commentstatus = 'singlecomment'">
	      <xsl:value-of select="/taboo/comm:reply/user:user/user:name"/>
	      <xsl:value-of select="i18n:include('comments-verb')"/>
	      <xsl:text>: </xsl:text>
	      <xsl:value-of select="/taboo/comm:reply/comm:title"/>
	      <xsl:text> | </xsl:text>
	    </xsl:when>
	  </xsl:choose>
	  <xsl:value-of select="/taboo/story:story/story:title"/>
	  <xsl:if test="@commentstatus='everything'">
	    <xsl:value-of select="i18n:include('with')"/>
	    <xsl:value-of select="i18n:include('comments')"/>
	  </xsl:if>
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
	  <xsl:call-template name="BreadcrumbNews"/>
	  <xsl:call-template name="BreadcrumbSection"/>

	  <!-- up to here, it is just the crumbs that needs to be there regardless of uri -->
	  <xsl:variable name="url-rest">
	    <xsl:value-of select="substring-after($request.uri, concat('/news/', story:story/story:sectionid, '/'))"/>
	  </xsl:variable>
	  <xsl:if test="starts-with(substring-after($url-rest, '/'), 'comment')">
	    <xsl:text> &gt; </xsl:text>
	    <!-- link to article without any comments -->
	    <a href="{substring-before($request.uri, 'comment/')}">
	      <xsl:value-of select="i18n:include('article-no-comments')"/>
	    </a>
	    <xsl:choose>
	      <xsl:when test="substring-after($url-rest, '/comment') = '/'">
	      </xsl:when>
	      <xsl:when test="substring-after($url-rest, '/comment') = '/all' or substring-after($url-rest, '/comment') = '/thread'">
		<xsl:text> &gt; </xsl:text>
		<a>
		  <xsl:attribute name="href">
		    <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
		    <xsl:text>comment/</xsl:text>
		  </xsl:attribute>
		  <xsl:value-of select="i18n:include('just')"/>
		  <xsl:value-of select="i18n:include('list-noun')"/>
		</a>
	      </xsl:when>
	      <xsl:otherwise>	
		<xsl:text> &gt; </xsl:text>
		<xsl:variable name="after-comment">
		  <xsl:value-of select="substring-after($request.uri, '/comment/')"/>
		</xsl:variable>

		<a>
		  <xsl:attribute name="href">
		    <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
		    <xsl:text>comment/</xsl:text>
		    <xsl:if test="contains($after-comment, '/thread')">
		      <xsl:text>thread</xsl:text>
		    </xsl:if>
		  </xsl:attribute>
		  <xsl:value-of select="i18n:include('comments')"/>
		</a>
		<xsl:call-template name="BreadcrumbNav">
		  <xsl:with-param name="commentpath">
		    <xsl:choose>
		      <xsl:when test="contains($after-comment, '/thread')">
			<!-- TODO: what really should be done is to make links to /thread --> 
			<xsl:value-of select="substring-before($after-comment, '/thread')"/>
		      </xsl:when>
		      <xsl:otherwise>
			<xsl:value-of select="$after-comment"/>
		      </xsl:otherwise>
		    </xsl:choose>
		  </xsl:with-param>
		  <xsl:with-param name="uri-before">
		    <xsl:value-of select="substring-before($request.uri, '/comment/')"/>
		    <xsl:text>/comment</xsl:text>
		  </xsl:with-param>
		</xsl:call-template>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:if>
	  <xsl:text> &gt; </xsl:text>
	</div>
	<div id="container">
	  <xsl:variable name="uri" select="concat('http://',
	    substring-before($request.headers.host, ':'), '/menu.xsp?VID=' , $session.id)"/>
	  <xsl:copy-of select="document($uri)"/>
	  <xsl:call-template name="CreateRightSidebar"/>
	  <div class="main">
	    <div id="the-story">
	      <xsl:apply-templates select="/taboo/story:story"/>
	    </div>
	    <xsl:if test="not(@commentstatus = 'singlecomment' or @commentstatus = 'threadonly')">
	      <div class="reply-link">
		<a>
		  <xsl:attribute name="href">
		    <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
		    <xsl:text>comment/respond</xsl:text>
		  </xsl:attribute>
		  <xsl:value-of select="i18n:include('reply-to-this')"/>
		</a>
	      </div>
	    </xsl:if>
	    <xsl:apply-templates select="/taboo/comm:reply"/>
	    <div class="commentlist">	      
	      <ul class="linktoall">
		<li>		
		  <a>
		    <xsl:attribute name="href">
		      <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
		      <xsl:text>comment/all</xsl:text>
		  </xsl:attribute>
		  <xsl:value-of select="i18n:include('everything-linktext')"/>
		  </a>
		</li>
	      </ul>
	      <xsl:apply-templates select="/taboo/comm:commentlist/comm:reply"/>
	    </div>
	  </div>
	</div>
	<xsl:call-template name="CreateFooter"/>
      </body>
    </html>
  </xsl:template>


  <!-- A template to process the usernames and add them as breadcrumbs -->
  <xsl:template name="BreadcrumbNav">
    <xsl:param name="commentpath"/>
    <xsl:param name="uri-before"/>
    <xsl:if test="contains($commentpath, '/')">
      <xsl:variable name="username">
	<xsl:value-of select="substring-before($commentpath, '/')"/>
      </xsl:variable>

      <xsl:text> &gt; </xsl:text>
      <a>
	<xsl:attribute name="href">
	  <xsl:value-of select="$uri-before"/>
	  <xsl:text>/</xsl:text>
	  <xsl:value-of select="$username"/>
	</xsl:attribute>
	<xsl:value-of select="i18n:include('by')"/>
	<xsl:value-of select="/taboo/comm:commentators/user:user[@user:key = $username]/user:name"/>
      </a>
      <xsl:call-template name="BreadcrumbNav">
	<xsl:with-param name="commentpath">
	  <xsl:value-of select="substring-after($commentpath, '/')"/>
	</xsl:with-param>
	<xsl:with-param name="uri-before">
	  <xsl:value-of select="concat($uri-before, '/', $username)"/>
	</xsl:with-param>
      </xsl:call-template>


    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
