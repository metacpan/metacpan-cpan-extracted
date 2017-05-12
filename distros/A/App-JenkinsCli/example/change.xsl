<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml"/>

    <xsl:template match="/">
        <xsl:apply-templates />
    </xsl:template>

    <!-- Change the value of stashUserPassword -->
    <xsl:template match="//project/publishers/org.jenkinsci.plugins.stashNotifier.StashNotifier/stashUserPassword/text()">
    </xsl:template>

    <!-- identity template -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
