<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

<xsl:include href="perlMethod.xsl"/>
<xsl:include href="perlFunction.xsl"/>
<xsl:include href="perlProperty.xsl"/>

<xsl:key name="properties-by-type" match="property" use="@type"/>

<!-- ========================================= -->
<!-- Template: perl class                    == -->
<!-- ========================================= -->

<xsl:template match="class">

	<xsl:if test="not(count(uses/*)=0)">
		<xsl:text>#dependent => [</xsl:text>
		<xsl:for-each select="dependencies/dependency">
			<xsl:apply-templates select="."/>
			<xsl:if test="not(position()=last())">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>];&#13;</xsl:text>
	</xsl:if>

	<xsl:if test="not(count(uses/*)=0)">
		<xsl:for-each select="uses/use">
			<xsl:apply-templates select="."/>
		</xsl:for-each>

		<xsl:text>&#13;</xsl:text>

		<xsl:if test="boolean(normalize-space(./info))">
			<xsl:text>=pod&#13;</xsl:text>
			<xsl:value-of select="./info"/>
			<xsl:text>.&#13;</xsl:text>
			<xsl:text>=cut&#13;&#13;</xsl:text>
		</xsl:if>
	</xsl:if>

	<xsl:text>use Class::Maker;&#13;&#13;</xsl:text>

	<xsl:text>package </xsl:text><xsl:value-of select="@name"/><xsl:text>;&#13;&#13;</xsl:text>

	<xsl:text>Class::Maker::class&#13;{&#13;</xsl:text>
	<xsl:if test="not(count(parents/*)=0)">
		<xsl:text>&#x0009;isa => [</xsl:text>
		<xsl:for-each select="parents/parent">
			<xsl:apply-templates select="."/>
			<xsl:if test="not(position()=last())">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>],&#13;&#13;</xsl:text>
	</xsl:if>

	<xsl:if test="properties/*">
		<xsl:text>&#x0009;public =>&#13;&#x0009;{&#13;</xsl:text>
		<xsl:for-each select="properties/property[count(. | key('properties-by-type', @type)[1]) = 1]">
			<xsl:sort select="@type" />
			<xsl:text>&#x0009;&#x0009;</xsl:text><xsl:value-of select="@type" />	<xsl:text> => [ </xsl:text>
			<xsl:for-each select="key('properties-by-type', @type)">
				<xsl:sort select="@name" />
				<xsl:text>&quot;</xsl:text><xsl:value-of select="@name" /><xsl:text>&quot;</xsl:text>
				<xsl:if test="not(position()=last())">
					<xsl:text>, </xsl:text>
				</xsl:if>
			</xsl:for-each>
			<xsl:text> ],&#13;</xsl:text>
		</xsl:for-each>
		<xsl:text>&#x0009;},&#13;</xsl:text>
	</xsl:if>

	<xsl:text>};&#13;</xsl:text>

	<xsl:if test="not(count(methods/*)=0)">
		<xsl:for-each select="methods/method">
			<xsl:apply-templates select="."/>
		</xsl:for-each>
	</xsl:if>

	<xsl:if test="not(count(functions/*)=0)">
		<xsl:for-each select="functions/function">
			<xsl:apply-templates select="."/>
		</xsl:for-each>
	</xsl:if>

	<xsl:text>&#13;1;&#13;__END__&#13;</xsl:text>
</xsl:template>

<!-- ========================================= -->
<!-- Template: perl dependency               == -->
<!-- ========================================= -->
<xsl:template match="dependency">
	<xsl:text>&quot;</xsl:text><xsl:value-of select="."/><xsl:text>&quot;</xsl:text>
</xsl:template>

<!-- ========================================= -->
<!-- Template: perl use                      == -->
<!-- ========================================= -->
<xsl:template match="use">
	<xsl:text>use </xsl:text>
	<xsl:value-of select="."/>
	<xsl:text>;&#13;</xsl:text>
</xsl:template>

<!-- ========================================= -->
<!-- Template: perl parent                   == -->
<!-- ========================================= -->
<xsl:template match="parent">
	<xsl:text>&quot;</xsl:text><xsl:value-of select="@name"/><xsl:text>&quot;</xsl:text>
</xsl:template>

</xsl:stylesheet>
