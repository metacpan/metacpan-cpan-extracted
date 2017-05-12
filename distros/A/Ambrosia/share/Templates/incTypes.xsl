<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="app://Ambrosia/EntityDataModel/2011/V1"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1"
    >

<xsl:strip-space elements="*" />
<xsl:output method="xml" indent="yes"  />

<xsl:template name="convertType">
	<xsl:param name="type" />

	<xsl:choose>
		<xsl:when test="$type='INT'">
			<xsl:text>Number</xsl:text>
		</xsl:when>
		<xsl:when test="$type='INTEGER'">
			<xsl:text>Number</xsl:text>
		</xsl:when>
		<xsl:when test="$type='SMALLINT'">
			<xsl:text>Number</xsl:text>
		</xsl:when>
		<xsl:when test="$type='TINYINT'">
			<xsl:text>Number</xsl:text>
		</xsl:when>

		<xsl:when test="$type='CHAR'">
			<xsl:text>String</xsl:text>
		</xsl:when>
		<xsl:when test="$type='VARCHAR'">
			<xsl:text>String</xsl:text>
		</xsl:when>

		<xsl:when test="$type='TEXT'">
			<xsl:text>Text</xsl:text>
		</xsl:when>

		<xsl:when test="$type='DOUBLE'">
			<xsl:text>Double</xsl:text>
		</xsl:when>
		<xsl:when test="$type='FLOAT'">
			<xsl:text>Double</xsl:text>
		</xsl:when>
		<xsl:when test="$type='DECIMAL'">
			<xsl:text>Double</xsl:text>
		</xsl:when>
		<xsl:when test="$type='NUMERIC'">
			<xsl:text>Double</xsl:text>
		</xsl:when>

		<xsl:when test="$type='BOOLEAN'">
			<xsl:text>Boolean</xsl:text>
		</xsl:when>

		<xsl:when test="$type='DATE'">
			<xsl:text>Date</xsl:text>
		</xsl:when>

		<xsl:when test="$type='DATETIME'">
			<xsl:text>Datetime</xsl:text>
		</xsl:when>

		<xsl:otherwise>
		<xsl:text>String</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
