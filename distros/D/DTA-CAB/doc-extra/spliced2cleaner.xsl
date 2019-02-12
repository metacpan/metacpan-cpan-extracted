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
  <xsl:param name="rootns" select="namespace-uri(/*)"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root -->
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: ignore partial tokens -->
  <xsl:template match="s/@part|w/@part|tei:s/@part|tei:w/@part" priority="100">
    <!-- ignore -->
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w -->
  <xsl:template match="w|tei:w" priority="10">
    <xsl:element namespace="{$rootns}" name="w">
      <xsl:apply-templates select="@id|@xml:id|@prev|@next|@t"/>
      <xsl:apply-templates select="lb|moot|tei:moot|ner|tei:ner|text()|comment()|processing-instruction()"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: moot|ner|a : remove namespaces -->
  <xsl:template match="moot|ner|a|tei:moot|tei:ner|tei:a" priority="10">
    <xsl:param name="lename" select="local-name(.)"/>
    <xsl:element namespace="{$rootns}" name="{$lename}">
      <xsl:apply-templates select="*|@*|text()|processing-instruction()|comment()"/>
    </xsl:element>
  </xsl:template>


  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: copy -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
