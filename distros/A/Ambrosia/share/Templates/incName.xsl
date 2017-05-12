<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:strip-space elements="*" />

<xsl:variable name="vLowercaseChars_CONST" select="'abcdefghijklmnopqrstuvwxyz'"/> 
<xsl:variable name="vUppercaseChars_CONST" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/> 

<xsl:variable name='UcAppName' select="translate(/atns:Application/@Name, $vLowercaseChars_CONST, $vUppercaseChars_CONST)" />
<xsl:variable name='LcAppName' select="translate(/atns:Application/@Name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)" />

<xsl:variable name='RealAppName' select="/atns:Application/@Name" />

<xsl:variable name="s_q">'</xsl:variable>
<xsl:variable name="d_q">"</xsl:variable>

</xsl:stylesheet>
