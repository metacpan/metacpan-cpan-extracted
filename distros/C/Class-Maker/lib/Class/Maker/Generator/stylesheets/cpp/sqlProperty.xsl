<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<!-- ========================================= -->
<!-- == Template: SQL property              == -->
<!-- ========================================= -->
<xsl:template match="property">
<!-- Database type -->
<xsl:variable name="dbtype"><xsl:choose>
    <xsl:when test="(normalize-space(@type)='string')"
    >varchar(50)</xsl:when>
    <xsl:when test="(normalize-space(@type)='int')"
    >numeric(10)</xsl:when>
    <xsl:when test="(normalize-space(@type)='double')"
    >numeric(15,7)</xsl:when>
    <xsl:otherwise>varchar(255)</xsl:otherwise>
</xsl:choose></xsl:variable>
<!-- property value -->
<xsl:if test="(@has_data='true')">
    <xsl:text>    </xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$dbtype"/>
    <xsl:if test="(@is_unique='true')">
        <xsl:text> CONSTRAINT </xsl:text>
        <xsl:value-of select="./../../@name"/>
        <xsl:text>_pk</xsl:text>
        <xsl:text> PRIMARY KEY</xsl:text></xsl:if></xsl:if>
</xsl:template> 

</xsl:stylesheet> 