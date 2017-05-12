<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html" version='1.0' encoding='UTF-8' indent="yes" />
  <!-- root rule -->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  <!-- main rule for document element -->
  <xsl:template match="upload">
    <xsl:variable name="percent" select="round(received div size * 100)"/>
    <xsl:variable name="remaining" select="size - received"/>
    <xsl:if test="$remaining">
      <meta http-equiv="refresh" content="1" />
    </xsl:if>
    <link rel="stylesheet" type="text/css" href="/UploadProgress/progress.css" />
    <div style="margin: 2% 10%">
      <h3>Upload Progress</h3>
      <div class="progressmeter">
        <div class="meter">
          <div class="amount">
            <xsl:attribute name="style">width: <xsl:value-of select="$percent"/>%;</xsl:attribute>
          </div>
          <div class="percent">
            <xsl:value-of select="$percent"/>%
          </div>
        </div>
        <table>
          <tbody>
            <tr>
              <th>Status:</th>
              <td>
                <xsl:choose>
                  <xsl:when test="$remaining">
                    <xsl:call-template name="format-bytes">
                      <xsl:with-param name="bytes" select="received"/>
                    </xsl:call-template>
                    of
                    <xsl:call-template name="format-bytes">
                      <xsl:with-param name="bytes" select="size"/>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <span class="finished">Transfer complete  (
                    <xsl:call-template name="format-bytes">
                      <xsl:with-param name="bytes" select="size"/>
                    </xsl:call-template>
                    )</span>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </xsl:template>
  <!-- prints-out bytes count -->
  <xsl:variable name="Mega" select="1024 * 1024"/>
  <xsl:variable name="Giga" select="1024 * $Mega"/>
  <xsl:template name="format-bytes">
    <xsl:param name="bytes" select="."/>
    <xsl:choose>
      <xsl:when test="$bytes &lt; 1024"><xsl:value-of select="format-number($bytes, '#,##0')"/>Bytes</xsl:when>
      <xsl:when test="$bytes &lt; $Mega"><xsl:value-of select="format-number($bytes div 1024, '#,###.##')"/>KB</xsl:when>
      <xsl:when test="$bytes &lt; $Giga"><xsl:value-of select="format-number($bytes div $Mega, '#,###.##')"/>MB</xsl:when>
      <xsl:when test="$bytes"><xsl:value-of select="format-number($bytes div $Giga, '#,###.##')"/>GB</xsl:when>
      <xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

