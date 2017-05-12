<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="//repository/mng_EWM">
	<xsl:apply-templates select="./error" />
	<xsl:apply-templates select="./warning" />
	<xsl:apply-templates select="./message" />
</xsl:template>

<xsl:template match="error">
	<div style="color: red;"><xsl:value-of select="@error" /></div>
</xsl:template>

<xsl:template match="warning">
	<div style="color: orange;"><xsl:value-of select="@warning" /></div>
</xsl:template>

<xsl:template match="message">
	<div style="color: green;"><xsl:value-of select="@message" /></div>
</xsl:template>

</xsl:stylesheet>
