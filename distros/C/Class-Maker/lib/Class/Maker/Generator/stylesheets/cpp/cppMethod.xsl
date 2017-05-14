<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<!-- ========================================= -->
<!-- == Template: method                    == -->
<!-- ========================================= -->
<xsl:template match="method">
<xsl:text>
</xsl:text>
<xsl:value-of select="@visibility"/><xsl:text>:
</xsl:text><xsl:text>    </xsl:text>
<xsl:value-of select="@modifier"/>
<xsl:if test="boolean(normalize-space(@modifier))">
     <xsl:text> </xsl:text></xsl:if>
<xsl:value-of select="@type"/><xsl:text> </xsl:text>
<xsl:value-of select="@name"/><xsl:text>(</xsl:text>
<!-- parameters -->
<xsl:for-each select="params/param">
    <xsl:apply-templates select="."/>
    <xsl:if test="not(position()=last())">  
        <xsl:text>, </xsl:text></xsl:if></xsl:for-each>
<xsl:text>)</xsl:text>
<xsl:if test="(@const='true')">
     <xsl:text> const</xsl:text></xsl:if>
<xsl:text>;
</xsl:text>

</xsl:template> 

<!-- ========================================= -->
<!-- == Template: param                     == -->
<!-- ========================================= -->
<xsl:template match="param">
<xsl:value-of select="@type"/>
<xsl:text> </xsl:text><xsl:value-of select="@name"/>
</xsl:template> 

</xsl:stylesheet> 

