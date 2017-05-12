<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:a="http://alvis.info/enriched/" 
           	xmlns="http://alvis.info/enriched/" 
		version="1.0">
<xsl:output method="text" encoding="UTF-8"/>

<!--  FUNCTION:  Print linkBags format for the record giving links
                 and named entities 
-->

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on alvis xml record -->
  <xsl:template match="a:documentRecord">

    <!-- First line:  format "D URL DOCID TITLE"  -->
    <xsl:text>D </xsl:text>
    <xsl:value-of select="a:acquisition/a:acquisitionData/a:urls/a:url"/>
     <xsl:text> </xsl:text>
    <xsl:value-of select="@id"/>
     <xsl:text> </xsl:text>
    <xsl:value-of select="a:acquisition/a:metaData/a:meta[@name='title']"/>
          <xsl:text>
</xsl:text>

  </xsl:template>


</xsl:stylesheet>
