<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<!-- ========================================= -->
<!-- == Template: property                  == -->
<!-- ========================================= -->
<xsl:template match="property">
<!-- get property -->
<xsl:if test="(@has_get='true')">
<xsl:text>
public:
</xsl:text>
    <xsl:text>    </xsl:text>
    <xsl:value-of select="@type"/><xsl:text> </xsl:text>
    <xsl:text>get</xsl:text><xsl:value-of select="@name"/>
    <xsl:text>() const
    {
        return </xsl:text>
    <xsl:text>_</xsl:text><xsl:value-of select="@name"/>
    <xsl:text>;
    }
    </xsl:text>
</xsl:if>
<!-- set property -->
<xsl:if test="(@has_set='true')">
<xsl:text>
public:
</xsl:text>
    <xsl:text>    </xsl:text>
    <xsl:value-of select="@type"/><xsl:text> </xsl:text>
    <xsl:text>set</xsl:text><xsl:value-of select="@name"/>
    <xsl:text>(</xsl:text>
    <xsl:value-of select="@type"/><xsl:text> </xsl:text>
    <xsl:text>value)
    {
        </xsl:text>
        <xsl:text>_</xsl:text><xsl:value-of select="@name"/>
        <xsl:text> = value;
    };
        </xsl:text>
</xsl:if>
<!-- property value -->
<xsl:if test="(@has_data='true')">
    <xsl:text>
private: 
    </xsl:text>
    <xsl:value-of select="@type"/><xsl:text> </xsl:text>
    <xsl:text>_</xsl:text><xsl:value-of select="@name"/>
    <xsl:text>;
    </xsl:text>
</xsl:if>
</xsl:template> 

</xsl:stylesheet> 