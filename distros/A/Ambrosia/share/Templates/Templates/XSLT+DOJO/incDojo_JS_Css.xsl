<?xml version="1.0" encoding="UTF-8" ?>
<xslt:stylesheet version="1.0" 
	xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/TransformAlias"
	xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xslt:strip-space elements="*" />

<xslt:template match="/">
<xsl:variable name="dojo_host" >/ajax/libs/dojo/1.7.2</xsl:variable>

<style type="text/css" media="screen">
	@import "<xsl:value-of select="$dojo_host" />/dojo/resources/dojo.css";
	@import "<xsl:value-of select="$dojo_host" />/dijit/themes/claro/claro.css";
	@import "<xsl:value-of select="$dojo_host" />/dijit/themes/claro/document.css";

	html, body {
		height: 100%;
		margin: 0;
		overflow: hidden;
		padding: 0;
		font-size: 1.1em;
		font-family: Geneva, Arial, Helvetica, sans-serif;
	}

	.heading {
		font-weight: bold;
		padding-bottom: 0.25em;
	}
</style>

<script>
	dojoConfig= {
		has: {
			"dojo-firebug": true
		},
		parseOnLoad: true,
		async: true
	};
</script>

<script type="text/javascript" src="">
	<xsl:attribute name="src"><xsl:value-of select="$dojo_host" />/dojo/dojo.js</xsl:attribute>
</script>

</xslt:template>

</xslt:stylesheet>