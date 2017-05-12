<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:cust="http://www.kjetil.kjernsmo.net/software/TABOO/NS/CustomGrammar"
  xmlns:comm="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  exclude-result-prefixes="cust user story comm cat i18n texts"> 

  <xsl:import href="../../../transforms/insert-i18n.xsl"/>
  <xsl:import href="match-user.xsl"/>

  <xsl:param name="request.uri"/>

  <xsl:template match="comm:reply">
    <div class="reply">
      <xsl:attribute name="id">
	<xsl:value-of select="comm:commentpath"/>
      </xsl:attribute>
      <div class="comm-head">
	<h3>
	  <xsl:choose>
	    <xsl:when test="/taboo[@commentstatus='threadonly'] or /taboo[@commentstatus='everything']">
	      <a>
		<xsl:attribute name="href">
		  <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
		  <xsl:text>comment</xsl:text>
		  <xsl:value-of select="comm:commentpath"/>
		</xsl:attribute>
		<xsl:value-of select="comm:title"/>
	      </a>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:value-of select="comm:title"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</h3>
	<div class="comm-byline">
	  <xsl:value-of select="i18n:include('posted-by')"/>
	  <xsl:apply-templates select="user:user"/>
	</div>    
	<div class="comm-timeinfo">
	  <xsl:value-of select="i18n:include('on-time')"/>
	  <xsl:apply-templates select="comm:timestamp"/>
	</div>
      </div>
      <div class="comm-content">
	<xsl:apply-templates select="comm:content/*" mode="strip-ns"/>
      </div>
      <xsl:if test="not(ancestor::comm:comment-loaded or ancestor::comm:comment-submission)">
	<div class="reply-link">
	  <a>
	    <xsl:attribute name="href">
	      <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
	      <xsl:text>comment</xsl:text>
	      <xsl:value-of select="comm:commentpath"/>
	      <xsl:text>/respond</xsl:text>
	    </xsl:attribute>
	    <xsl:value-of select="i18n:include('reply-to-this')"/>
	    <xsl:value-of select="i18n:include('comment')"/>
	  </a>
	</div>
      </xsl:if>

      <xsl:apply-templates select="comm:reply"/>

    </div>
  </xsl:template>

  <xsl:template match="comm:commentlist//comm:reply">
    <ul>
      <li>
	<xsl:choose>
	  <xsl:when test="substring-after($request.uri, '/comment') != comm:commentpath">
	    <a>
	      <xsl:attribute name="href">
		<xsl:value-of select="substring-before($request.uri, 'comment/')"/>
		<xsl:text>comment</xsl:text>
		<xsl:value-of select="comm:commentpath"/>
	      </xsl:attribute>
	      <xsl:value-of select="comm:title"/>
	    </a>
	  </xsl:when>
	  <xsl:otherwise>
	      <xsl:value-of select="comm:title"/>
	  </xsl:otherwise>
	</xsl:choose>
	<xsl:text> ( </xsl:text>
	<a>
	  <xsl:attribute name="href">
	    <xsl:value-of select="substring-before($request.uri, 'comment/')"/>
	    <xsl:text>comment</xsl:text>
	    <xsl:value-of select="comm:commentpath"/>
	    <xsl:text>/thread</xsl:text>
	  </xsl:attribute>
	  <xsl:value-of select="i18n:include('thread-below')"/>
	</a>
	<xsl:text> ) </xsl:text>
	
      </li>
      <xsl:apply-templates select="comm:reply"/>
    </ul>
  </xsl:template>

  <xsl:template match="*" mode="strip-ns">
    <xsl:element name="{local-name()}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="strip-ns"/>
    </xsl:element>
  </xsl:template>


</xsl:stylesheet>
