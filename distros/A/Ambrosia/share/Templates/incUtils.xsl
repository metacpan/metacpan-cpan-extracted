<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="app://Ambrosia/EntityDataModel/2011/V1"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1"
    >

<xsl:template name="join" >
  <xsl:param name="valueList" select="''"/>
  <xsl:param name="separator" select="','"/>
  <xsl:for-each select="$valueList">
    <xsl:choose>
      <xsl:when test="position() = 1">
        <xsl:value-of select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($separator, .) "/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
