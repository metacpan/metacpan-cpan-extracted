<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY laquo    "&#171;">
<!ENTITY larr    "&#8592;">
<!ENTITY nbsp    "&#160;">
<!ENTITY ndash   "&#8211;">
<!ENTITY numero  "&#8470;">
<!ENTITY mdash   "&#8212;">
<!ENTITY raquo    "&#187;">
]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">
<xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>

<xsl:template match="opt">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ru" xml:lang="ru">
	<head>
		<meta charset="utf-8"/>
		<title>Creazilla.com</title>
	</head>
	<body>
		<h1>Creazilla</h1>
		<p>test=<xsl:value-of select="/opt/@test"/></p>
	</body>
</html>
</xsl:template>

</xsl:stylesheet>