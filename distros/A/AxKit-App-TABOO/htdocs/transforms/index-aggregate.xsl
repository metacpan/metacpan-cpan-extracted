<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:aggr="http://www.kjetil.kjernsmo.net/software/TABOO/NS/IndexAggr"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category"
  xmlns="http://www.w3.org/1999/xhtml">
  <xsl:output encoding="utf-8"
    media-type="text/xml" indent="yes"/>
  
  <xsl:param name="session.id"/>
  <xsl:param name="request.headers.host"/>

  <xsl:template match="*|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/taboo/aggr:stories">
    <xsl:for-each select="aggr:story">
      <!-- constructing the URI using Apache::AxKit::Plugin::Passthru
	   and Apache::AxKit::Plugin::AddXSLParams::Request -->
      <xsl:variable name="uri" select="concat('http://',
				       substring-before($request.headers.host, ':'), ., '?passthru=1&amp;VID=', $session.id)"/>
      
      <xsl:copy-of select="document($uri)"/>
    </xsl:for-each>
  </xsl:template>



</xsl:stylesheet>
  