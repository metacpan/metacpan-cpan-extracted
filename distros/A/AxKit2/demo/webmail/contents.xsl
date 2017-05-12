<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="1.0">

<xsl:output method="xml"/>


<xsl:template match="/webmail">

<div class="title">Mails in folder <xsl:value-of select="contents/@folder"/></div>
<table>
    <tr>
        <th>From</th><th>Subject</th><th>Date </th><th> Received</th>
    </tr>
    
    <tr><td colspan="4" align="center" class="pageset">
        <xsl:if test="pageset/previous">
            <span style="color: blue" onclick="load_folder_page('{/webmail/contents/@folder}', {pageset/previous})">&lt;&lt; Prev</span>
        </xsl:if>
        <xsl:for-each select="pageset/page">
            &#160;
            <xsl:choose>
                <xsl:when test="@current"><xsl:value-of select="."/></xsl:when>
                <xsl:otherwise>
                    <span style="color: blue" onclick="load_folder_page('{/webmail/contents/@folder}', {text()});"><xsl:value-of select="."/></span>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:if test="pageset/next">
            &#160;
            <span style="color: blue" onclick="load_folder_page('{/webmail/contents/@folder}', {pageset/next})">Next >></span>
        </xsl:if>
    </td></tr>
    
    <xsl:apply-templates select="contents"/>
</table>

</xsl:template>

<xsl:template match="contents">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="mail">
    <tr style=":hover {{ background: #faa }}" onclick="load_message('{/webmail/contents/@folder}', {@id})">
        <td><xsl:value-of select="from"/></td>
        <td><xsl:value-of select="subject"/></td>
        <td><xsl:value-of select="received_at/date"/></td>
        <td><xsl:value-of select="received_at/time"/></td>
    </tr>
</xsl:template>

</xsl:stylesheet>
