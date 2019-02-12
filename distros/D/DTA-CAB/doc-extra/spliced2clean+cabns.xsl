<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		xmlns:cab="http://deutschestextarchiv.de/ns/cab/1.0"
		exclude-result-prefixes="cab"
		>

  <xsl:output method="xml" version="1.0" indent="no" encoding="UTF-8"/>
  
  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <!--<xsl:strip-space elements="s l"/>-->
  
  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- parameters -->
  <xsl:param name="rootns" select="namespace-uri(/*)"/>		

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root -->
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:attribute name="cab:root"/>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: ignore stuff -->
  <xsl:template match="s/@part|w/@part|tei:s/@part|tei:w/@part" priority="100">
    <!-- ignore -->
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: id -> xml:id -->
  <xsl:template match="@id|@tei:id" priority="100">
    <xsl:attribute name="xml:id"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w -->
  <xsl:template match="w|tei:w" priority="10">
    <xsl:element namespace="{$rootns}" name="w">
      <xsl:if test="@t"><xsl:attribute name="cab:t"><xsl:value-of select="@t"/></xsl:attribute></xsl:if>
      <xsl:if test="moot|tei:moot">
	<xsl:attribute name="cab:word"><xsl:value-of select="moot/@word|tei:moot/@word"/></xsl:attribute>
	<xsl:attribute name="cab:tag"><xsl:value-of select="moot/@tag|tei:moot/@tag"/></xsl:attribute>
	<xsl:attribute name="cab:lemma"><xsl:value-of select="moot/@lemma|tei:moot/@lemma"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="@id|@prev|@next|ner|tei:ner|text()"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //ner -->
  <xsl:template match="ner|tei:ner">
    <xsl:element name="cab:ner">
      <xsl:apply-templates select="@*|*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //ner/a|toka/a -->
  <!--  : NOTE: toka is currently ignored by //w template -->
  <xsl:template match="ner/a|tei:ner/tei:a|toka/a|tei:toka/tei:a">
    <xsl:element namespace="{$rootns}" name="a"><xsl:apply-templates select="@*|*"/></xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: copy -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
