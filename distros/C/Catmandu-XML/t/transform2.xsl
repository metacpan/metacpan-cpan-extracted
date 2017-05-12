<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text"/>
    <xsl:template match="doc">
        <xsl:text>DOC: </xsl:text>
        <xsl:value-of select="./@attr"/>
    </xsl:template>
</xsl:stylesheet>
