<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:template match="root">
<root>
  <xsl:copy-of select="document('03_document.xml')"/>
</root>
</xsl:template>

</xsl:stylesheet>

