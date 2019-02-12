<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		>

  <xsl:output method="xml" version="1.0" indent="no" encoding="UTF-8"/>
  
  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <xsl:strip-space elements="xlit moot ner toka a tei:xlit tei:moot tei:ner tei:toka tei:a"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- parameters -->
  <xsl:param name="rootns" select="namespace-uri(/*)"/>
  <xsl:key   name="wtype"  match="w|tei:w" use="@t" />

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- header: template: extent: tokens (number of initial //w fragments) -->
  <xsl:template match="//teiHeader//extent//measure[@type='tokens']/text()|//tei:teiHeader//tei:extent/tei:measure[@type='tokens']/text()" priority="10">
    <xsl:value-of select="count(//w[not(@prev)]|//tei:w[not(@prev)])"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- header: template: extent: types (surface text from //w/@t) -->
  <xsl:template match="//teiHeader//extent//measure[@type='types']/text()|//tei:teiHeader//tei:extent/tei:measure[@type='types']/text()" priority="10">
    <xsl:value-of select="count(//w    [not(@prev) and generate-id() = generate-id(key('wtype',@t)[1])]
			       |//tei:w[not(@prev) and generate-id() = generate-id(key('wtype',@t)[1])])"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w -->
  <xsl:template match="w|tei:w" priority="10">
    <xsl:param name="tag"     select="moot/@tag|tei:moot/@tag"/>
    <xsl:param name="wleft"   select="preceding-sibling::node()[1][local-name()='w']"/>
    <xsl:param name="wright"  select="following-sibling::node()[1][local-name()='w']"/>
    <xsl:element namespace="{$rootns}" name="w">
      <xsl:apply-templates select="@id|@tei:id|@xml:id|@prev|@next|@part"/>
      <!-- join attribute (whitespace separation): from XML adjacency -->
      <xsl:choose>
	<xsl:when test="$wleft and $wright"><xsl:attribute name="join">both</xsl:attribute></xsl:when>
	<xsl:when test="$wleft"><xsl:attribute name="join">left</xsl:attribute></xsl:when>
	<xsl:when test="$wright"><xsl:attribute name="join">right</xsl:attribute></xsl:when>
      </xsl:choose>
      <!-- alternative: join attribute: from @ws attribute as supplied by dtatw_get_ddc_attrs.perl -->
      <!--
      <xsl:param name="wnxt"  select="following-sibling::w[1]|following-sibling::tei:w[1]"/>
      <xsl:choose>
	<xsl:when test="@ws='0' and $wnxt/@ws='0'"><xsl:attribute name="join">both</xsl:attribute></xsl:when>
	<xsl:when test="@ws='0' and not($wnxt/@ws='0')"><xsl:attribute name="join">left</xsl:attribute></xsl:when>
	<xsl:when test="@ws='1' and $wnxt/@ws='0'"><xsl:attribute name="join">right</xsl:attribute>/xsl:when>
      </xsl:choose>
      -->
      <xsl:apply-templates select="*|text()|processing-instruction()|comment()"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w/@id -->
  <xsl:template match="w[not(@xml:id)]/@id|tei:w[not(@xml:id)]/@id" priority="10">
    <xsl:attribute name="xml:id"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //s/@id -->
  <xsl:template match="s[not(@xml:id)]/@id|tei:s[not(@xml:id)]/@id" priority="10">
    <xsl:attribute name="xml:id"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  
  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w/moot -->
  <xsl:template match="w/moot|tei:w/tei:moot" priority="10">
    <xsl:attribute name="lemma"><xsl:value-of select="@lemma"/></xsl:attribute>
    <xsl:attribute name="pos"><xsl:value-of select="@tag"/></xsl:attribute>
    <xsl:attribute name="norm"><xsl:value-of select="@word"/></xsl:attribute>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w/{CAB_ELT} : ignore -->
  <xsl:template match="w//xlit|w//ner|w//a|w//toka|w//morph|w//mlatin|tei:w//tei:xlit|tei:w//tei:ner|tei:w//tei:a|tei:w//tei:toka|tei:w//tei:morph|tei:w//tei:mlatin" priority="5">
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //s/@{CAB_ATTR} -->
  <xsl:template match="s/@pn|tei:s/@pn" priority="5">
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: copy -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
