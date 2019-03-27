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
  <!--<xsl:strip-space elements="moot ner toka a tei:moot tei:ner tei:toka tei:a"/>-->


  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root -->
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: ignore stuff -->
  <xsl:template match="s/@part|w/@part|tei:s/@part|tei:w/@part" priority="100">
    <!-- ignore -->
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //w -->
  <xsl:template match="w|tei:w" priority="10">
    <xsl:choose>
      <xsl:when test="@norm">
	<xsl:value-of select="@norm"/>
      </xsl:when>
      <xsl:when test="@prev or @next">
	<!-- ignore -->
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="*|processing-instruction()|comment()|text()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //s: just recurse -->
  <xsl:template match="s|tei:s" priority="10">
    <xsl:apply-templates select="*|text()|processing-instruction()|comment()"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: copy -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
