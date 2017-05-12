<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="1.0">

<xsl:output method="xml"/>

<xsl:template match="uri|base-uri|user"/>

<xsl:template match="/webmail/mailboxes">
    <ul>
        <xsl:apply-templates/>
    </ul>
</xsl:template>

<xsl:template match="mailbox">
    <li><div onclick="load_folder('{name}')"><xsl:value-of select="name"/> (<xsl:value-of select="count"/>)</div></li>
</xsl:template>

</xsl:stylesheet>
