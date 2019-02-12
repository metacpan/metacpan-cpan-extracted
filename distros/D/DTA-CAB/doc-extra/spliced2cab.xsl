<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- globals -->

  <xsl:output method="xml" version="1.0" indent="yes" encoding="UTF-8"/>
  <xsl:key name="rawid" match="s|w|tei:s|tei:w" use="@id"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: root -->
  <xsl:template match="/*" priority="100">
    <xsl:element name="doc">
      <xsl:apply-templates select="@xml:base|@tei:base|@base|//s|//tei:s"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: chains: non-initial elements -->
  <xsl:template match="*[@prev]" priority="20">
    <!-- content of these should get pulled in by named template "chain.next" -->
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: chain attributes: ignore -->
  <xsl:template match="@prev|@next|lb|pb|fw" priority="20">
    <!-- ignore -->
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: NAMED: chain.first -->
  <xsl:template name="chain.first">
    <xsl:param name="lname" select="local-name()"/>
    <xsl:element name="{$lname}">
      <xsl:apply-templates select="@*|*|text()"/>
      <xsl:if test="@next">
	<xsl:call-template name="chain.next">
	  <xsl:with-param name="nextid" select="@next"/>
	</xsl:call-template>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: NAMED: chain.next -->
  <xsl:template name="chain.next">
    <xsl:param name="nextid" select="./@next"/>
    <xsl:param name="nextnod" select="key('rawid',$nextid)"/>
    <xsl:if test="$nextid">
      <xsl:apply-templates select="$nextnod/*"/>
      <xsl:call-template name="chain.next">
	<xsl:with-param name="nextid" select="$nextnod/@next"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: CAB structure: fragmented -->
  <xsl:template match="s|tei:s|w|tei:w|w//*|tei:w//*">
    <xsl:call-template name="chain.first"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: text: kept -->
  <xsl:template match="@*|w//a//text()|tei:w//tei:a//text()">
    <xsl:copy/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- default: just recurse -->
  <xsl:template match="*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:apply-templates select="*|text()|processing-instruction()|comment()"/>
  </xsl:template>

</xsl:stylesheet>
