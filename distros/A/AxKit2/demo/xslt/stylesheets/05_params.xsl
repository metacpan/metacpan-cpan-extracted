<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:param name="p1">no value</xsl:param>
<xsl:param name="p2">no value</xsl:param>
<xsl:template match="root">
<root>
  <xsl:value-of select="concat( $p1, ' ', $p2 )"/>
</root>
</xsl:template>

</xsl:stylesheet>

