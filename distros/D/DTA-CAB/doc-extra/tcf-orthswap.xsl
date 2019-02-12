<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:tc="http://www.dspin.de/data/textcorpus"
  >
  <xsl:output method="xml" version="1.0" indent="no" encoding="UTF-8"/>
  
  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- keys -->
  <xsl:key name="key.tok" match="tc:tokens/tc:token" use="@ID"/>
  <xsl:key name="key.cor" match="tc:orthography/tc:correction[@operation='replace']" use="@tokenIDs"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root -->
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: token := correction -->
  <xsl:template match="tc:token[key('key.cor',@ID)]/text()">
    <xsl:value-of select="key('key.cor',../@ID)/text()"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: correction := token -->
  <xsl:template match="tc:correction[@operation='replace' and key('key.tok',@tokenIDs)]/text()">
    <xsl:value-of select="key('key.tok',../@tokenIDs)/text()"/>
  </xsl:template>
  
  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: copy -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
