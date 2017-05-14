<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<!-- ========================================= -->
<!-- == Template: method                    == -->
<!-- ========================================= -->
<xsl:template match="method">
	<xsl:text>&#13;sub </xsl:text>
	<xsl:value-of select="@name"/>

	<xsl:choose>
		<xsl:when test="@proto">
			<xsl:text>( </xsl:text>
			<xsl:value-of select="@proto"/>
			<xsl:text> )</xsl:text>
		</xsl:when>
		<xsl:otherwise>
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
		</xsl:otherwise>
	</xsl:choose>
	
	<xsl:text> : method</xsl:text>
	
	<xsl:text>&#13;{&#13;&#x0009;my $this = shift;&#13;</xsl:text>

	<xsl:for-each select="params/param">
		<xsl:text>&#x0009;my </xsl:text><xsl:value-of select="@type"/><xsl:value-of select="@name"/><xsl:text>;&#13;</xsl:text>
		<xsl:if test="not(position()=last())">  
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:for-each>
	
	<xsl:text>&#13;return; &#13;}&#13;</xsl:text>

</xsl:template> 

<!-- ========================================= -->
<!-- == Template: param                     == -->
<!-- ========================================= -->
<xsl:template match="param">
	<xsl:value-of select="@type"/>
</xsl:template> 

</xsl:stylesheet> 

