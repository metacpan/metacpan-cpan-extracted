<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
<xsl:output method="text"/>

<xsl:include href="SqlProperty.xsl"/>

<!-- ========================================= -->
<!-- Template: SQL class                    == -->
<!-- ========================================= -->
<xsl:template match="class">
<!-- file header -->
<xsl:text>-- table: </xsl:text>
<xsl:value-of select="@name"/><xsl:text>s</xsl:text>
<!-- table documentation -->
<xsl:text>
</xsl:text>
<xsl:if test="boolean(normalize-space(./info))">
    <xsl:text>
-- </xsl:text>
    <xsl:text>
-- </xsl:text><xsl:value-of select="./info"/>
    <xsl:text>
-- </xsl:text></xsl:if>
<!-- table DDL -->
<xsl:text>
CREATE TABLE </xsl:text>
<xsl:value-of select="@name"/><xsl:text>s</xsl:text>
<xsl:text> 
(
</xsl:text>
<!-- properties -->
<xsl:for-each select="properties/property">
    <xsl:apply-templates select="."/>
    <xsl:if test="not(position()=last())">  
        <xsl:text>,
</xsl:text></xsl:if></xsl:for-each>
<xsl:text>
) </xsl:text>
</xsl:template> 

</xsl:stylesheet> 