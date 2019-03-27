<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tei="http://www.tei-c.org/ns/1.0"
		>
		<!--
		    xmlns:cab="http://deutschestextarchiv.de/ns/cab/1.0"
		    exclude-result-prefixes="cab"
		-->

  <xsl:output method="text" version="1.0" indent="no" encoding="UTF-8"/>

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
	<!-- ignore fragmented elements -->
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates select="*|processing-instruction()|comment()|text()"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="not(@join = 'right' or @join = 'both')">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: //lb -->
  <xsl:template match="lb|tei:lb|p|tei:p|div|tei:div" priority="10">
    <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: just recurse -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
  </xsl:template>

</xsl:stylesheet>
