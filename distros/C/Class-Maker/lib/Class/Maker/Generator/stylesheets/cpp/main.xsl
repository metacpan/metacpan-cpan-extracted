<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
<xsl:output method="text"/>

<xsl:include href="CppMethod.xsl"/>
<xsl:include href="CppProperty.xsl"/>

<!-- ========================================= -->
<!-- Template: C++ class                    == -->
<!-- ========================================= -->
<xsl:template match="class">
<!-- file header -->
<xsl:text>// file: </xsl:text>
<xsl:value-of select="@name"/><xsl:text>.h</xsl:text>
<xsl:text>
<!-- multiple includes protection -->
#ifndef _</xsl:text><xsl:value-of select="@name"/><xsl:text>_H_
#define _</xsl:text><xsl:value-of select="@name"/><xsl:text>_H_
</xsl:text>
<!-- dependencies -->
<xsl:text>
// Dependencies
</xsl:text>
<xsl:for-each select="dependencies/dependency">
    <xsl:apply-templates select="."/></xsl:for-each>
<xsl:text>
// Uses
</xsl:text>
<xsl:for-each select="uses/use">
    <xsl:apply-templates select="."/></xsl:for-each>
<!-- class documentation -->
<xsl:text>
</xsl:text>
<xsl:if test="boolean(normalize-space(./info))">
    <xsl:text>/** </xsl:text><xsl:value-of select="./info"/>
    <xsl:text>.
</xsl:text>
    <xsl:text> */
</xsl:text></xsl:if>
<!-- class declaration -->
<xsl:text>class </xsl:text><xsl:value-of select="@name"/>
<!-- inheritance -->
<xsl:if test="not(count(parents/*)=0)">
    <xsl:text> : </xsl:text></xsl:if>
<xsl:for-each select="parents/parent">
    <xsl:apply-templates select="."/>
    <xsl:if test="not(position()=last())">
        <xsl:text>, </xsl:text></xsl:if></xsl:for-each>
<!-- class body -->
<xsl:text>
{</xsl:text>
<!-- methods -->
<xsl:if test="not(count(methods/*)=0)"><xsl:text>
// Methods
</xsl:text></xsl:if>
<xsl:for-each select="methods/method">
    <xsl:apply-templates select="."/></xsl:for-each>
<!-- properties -->
<xsl:if test="not(count(properties/*)=0)"><xsl:text>
// Properties
</xsl:text></xsl:if>
<xsl:for-each select="properties/property">
    <xsl:apply-templates select="."/></xsl:for-each>
<xsl:text>
};// class: </xsl:text><xsl:value-of select="@name"/>
<xsl:text>
<!-- multiple includes protection -->
#endif // _</xsl:text><xsl:value-of select="@name"/>
<xsl:text>_H_</xsl:text>
</xsl:template>

<!-- ========================================= -->
<!-- Template: C++ dependency               == -->
<!-- ========================================= -->
<xsl:template match="dependency">
<xsl:text>#include &quot;</xsl:text>
<xsl:value-of select="."/><xsl:text>.h&quot;</xsl:text>
</xsl:template>

<!-- ========================================= -->
<!-- Template: C++ use                      == -->
<!-- ========================================= -->
<xsl:template match="use">
<xsl:text>#include &lt;</xsl:text>
<xsl:value-of select="."/><xsl:text>&gt;
</xsl:text>
<xsl:if test="(normalize-space(.)='string')">
    <xsl:text>using namespace std;
    </xsl:text></xsl:if>
</xsl:template>

<!-- ========================================= -->
<!-- Template: C++ parent                   == -->
<!-- ========================================= -->
<xsl:template match="parent">
<xsl:value-of select="@visibility"/>
<xsl:text> </xsl:text><xsl:value-of select="@name"/>
</xsl:template>

</xsl:stylesheet> 