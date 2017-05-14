<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text"/>

	<!-- ========================================= -->
	<!-- Template: SQL class                    == -->
	<!-- ========================================= -->
	<xsl:template match="class">
		<xsl:text>-- table: </xsl:text><xsl:value-of select="@name"/>
		<xsl:text>&#13;</xsl:text>
		<xsl:if test="boolean(normalize-space(./info))">
			<xsl:text>--&#13;</xsl:text>
			<xsl:text>-- </xsl:text><xsl:value-of select="./info"/><xsl:text>&#13;</xsl:text>
			<xsl:text>--&#13;</xsl:text>
		</xsl:if>
		<xsl:text>CREATE TABLE &quot;</xsl:text><xsl:value-of select="@name"/><xsl:text>s&quot;</xsl:text>
		<xsl:text>&#13;(&#13;</xsl:text>
		<xsl:for-each select="properties/property[@has_data]">
			<xsl:apply-templates select="."/>
			<xsl:if test="not(position()=last())">
				<xsl:text>,&#13;</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>&#13;)&#13;</xsl:text>
	</xsl:template>

	<xsl:template match="property">
		<xsl:variable name="dbtype">
			<xsl:choose>
				<xsl:when test="(normalize-space(@type)='string')">varchar(50)</xsl:when>
				<xsl:when test="(normalize-space(@type)='int')">numeric(10)</xsl:when>
				<xsl:when test="(normalize-space(@type)='double')">numeric(15,7)</xsl:when>
				<xsl:otherwise>varchar(255)</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="(@has_data='true')">
			<xsl:text>&#x0009;</xsl:text><xsl:value-of select="@name"/><xsl:text> </xsl:text>
			<xsl:value-of select="$dbtype"/>
			<xsl:if test="(@is_unique='true')">
				<xsl:text> CONSTRAINT </xsl:text>
				<xsl:value-of select="./../../@name"/>
				<xsl:text>_pk</xsl:text>
				<xsl:text> PRIMARY KEY</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
