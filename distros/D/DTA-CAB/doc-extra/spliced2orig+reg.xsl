<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		>
		<!--
		    xmlns:cab="http://deutschestextarchiv.de/ns/cab/1.0"
		    exclude-result-prefixes="cab"
		-->

  <xsl:output method="xml" version="1.0" indent="no" encoding="UTF-8"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <xsl:strip-space elements="moot ner toka a tei:moot tei:ner tei:toka tei:a"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- parameters -->
  <xsl:param name="regresp">#cab</xsl:param>
  <xsl:param name="rootns" select="namespace-uri(/*)"/>		

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root -->
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: sub-token structure: ignore -->
  <xsl:template match="moot|tei:moot|xlit|tei:xlit|toka|tei:toka|ner|tei:ner" priority="10"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: sentence structure: just recurse -->
  <xsl:template match="s|tei:s" priority="10">
    <xsl:apply-templates select="*|text()|processing-instruction()|comment()"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w guts -->
  <xsl:template name="w_choice">
    <xsl:param name="reg" select="./moot/@word|./tei:moot/@word"/>
    <!--<xsl:message>w_choice: orig=<xsl:value-of select="./text()"/> ; reg=<xsl:value-of select="$reg"/>&#10;</xsl:message>-->
    <xsl:element namespace="{$rootns}" name="choice">
      <xsl:element namespace="{$rootns}" name="orig">
	<xsl:apply-templates select="text()|processing-instruction()|comment()|*"/>
      </xsl:element>
      <xsl:element namespace="{$rootns}" name="reg">
	<xsl:if test="$regresp != ''">
	  <xsl:attribute name="resp"><xsl:value-of select="$regresp"/></xsl:attribute>
	</xsl:if>
	<xsl:value-of select="$reg"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w -->
  <xsl:template match="w|tei:w" priority="10">
    <xsl:choose>
      <xsl:when test="@prev">
	<xsl:call-template name="w_choice"/>
      </xsl:when>
      <xsl:when test="./moot     and text() != ./moot/@word">
	<xsl:call-template name="w_choice"/>
      </xsl:when>
      <xsl:when test="./tei:moot and text() != ./tei:moot/@word">
	<xsl:call-template name="w_choice"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="text()|processing-instruction()|comment()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: copy -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
