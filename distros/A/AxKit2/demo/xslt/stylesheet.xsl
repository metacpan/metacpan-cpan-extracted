<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

<xsl:output method="html"/>

<xsl:template match="/">
    <html>
        <xsl:apply-templates/>
    </html>
</xsl:template>

<xsl:template match="head">
<head><xsl:apply-templates/></head>
</xsl:template>

<xsl:template match="head/title">
<title><xsl:apply-templates/></title>
</xsl:template>

<xsl:template match="body">
<body><xsl:apply-templates/></body>
</xsl:template>

<xsl:template match="section">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="section/title">
    <h1><xsl:apply-templates/></h1>
</xsl:template>

<xsl:template match="para">
    <p>
    <xsl:apply-templates/>
    </p>
</xsl:template>

</xsl:stylesheet>