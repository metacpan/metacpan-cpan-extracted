<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<!-- ========================================= -->
<!-- == Template: method                    == -->
<!-- ========================================= -->
<xsl:template match="function">
	<xsl:text>&#13;sub </xsl:text>
	<xsl:value-of select="@name"/>
	
	<xsl:if test="params/param">
		<xsl:text>( </xsl:text>
		<xsl:for-each select="params/param">
			<xsl:apply-templates select="."/>
			<xsl:if test="not(position()=last())">  
				<xsl:text> </xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text> )</xsl:text>
	</xsl:if>
	
	<xsl:if test="@type">
		<xsl:text> : </xsl:text>
		<xsl:value-of select="@type"/>
	</xsl:if>
	
	<xsl:text>&#13;{&#13;&#13;return; &#13;}&#13;</xsl:text>
</xsl:template> 

<!-- ========================================= -->
<!-- == Template: param                     == -->
<!-- ========================================= -->
<xsl:template match="param">
	<xsl:value-of select="@type"/>
</xsl:template> 

</xsl:stylesheet> 

