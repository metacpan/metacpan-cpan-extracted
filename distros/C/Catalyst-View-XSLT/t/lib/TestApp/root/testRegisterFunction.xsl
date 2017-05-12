<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:catalyst="urn:catalyst"	
	version="1.0">
		
		<xsl:output method="text" />

        <xsl:template match="/">
				
			<xsl:value-of select="catalyst:test()" />

        </xsl:template>

</xsl:stylesheet>
