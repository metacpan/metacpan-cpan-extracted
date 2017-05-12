<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	version="1.0">

	<xsl:output method="text" />
	<xsl:param name="message" />

	<xsl:template match="/">
			<xsl:value-of select="$message" disable-output-escaping="yes" />
	</xsl:template>

</xsl:stylesheet>
