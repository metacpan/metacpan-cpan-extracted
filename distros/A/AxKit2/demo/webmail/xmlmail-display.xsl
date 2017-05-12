<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="1.0">

<xsl:output method="xml"/>

<xsl:param name="max-header-length" select="70"/>

<xsl:template match="/">
    <div class="mailviewer">
        <xsl:apply-templates/>
    </div>
</xsl:template>

<xsl:template match="uri|base-uri|user"/>

<xsl:template match="/webmail">
    <xsl:apply-templates match="xmlmail"/>
</xsl:template>

<xsl:template match="xmlmail">
    <div class="email">
        <xsl:apply-templates/>
    </div>
</xsl:template>

<xsl:template match="xmlmail/header">
    <div class="emailheader">
        <xsl:apply-templates select="from"/>
        <xsl:apply-templates select="date"/>
        <xsl:apply-templates select="to"/>
        <xsl:apply-templates select="cc"/>
        <xsl:apply-templates select="subject"/>
        <xsl:apply-templates select="x-header"/>
    </div>
</xsl:template>

<xsl:template match="xmlmail/header/from">
    <div class="headerline">
        <b>From:</b>&#160;
        <xsl:call-template name="truncate-string">
            <xsl:with-param name="length" select="$max-header-length"/>
            <xsl:with-param name="string" select="text()"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="xmlmail/header/subject">
    <div class="headerline">
        <b>Subject:</b>&#160;
        <xsl:call-template name="truncate-string">
            <xsl:with-param name="length" select="$max-header-length"/>
            <xsl:with-param name="string" select="text()"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="xmlmail/header/date">
    <div class="headerline">
        <b>Date:</b>&#160;
        <xsl:call-template name="truncate-string">
            <xsl:with-param name="length" select="$max-header-length"/>
            <xsl:with-param name="string" select="text()"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="xmlmail/header/to">
    <div class="headerline">
        <b>To:</b>&#160;
        <xsl:call-template name="truncate-string">
            <xsl:with-param name="length" select="$max-header-length"/>
            <xsl:with-param name="string" select="text()"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="xmlmail/header/cc">
    <div class="headerline">
        <b>Cc:</b>&#160;
        <xsl:call-template name="truncate-string">
            <xsl:with-param name="length" select="$max-header-length"/>
            <xsl:with-param name="string" select="text()"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="xmlmail/header/x-header">
    <div class="headerline">
        <b><xsl:value-of select="name"/>:</b>&#160;
        <xsl:call-template name="truncate-string">
            <xsl:with-param name="length" select="$max-header-length"/>
            <xsl:with-param name="string" select="value/text()"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match="xmlmail/body">
    <div class="emailbody">
        <xsl:apply-templates/>
    </div>
</xsl:template>

<xsl:template match="htmlpart[@pre='1']">
    <!-- <div class="marker">HTML Part (decoded to text):</div> -->
    <pre>
    <xsl:apply-templates/>
    </pre>
</xsl:template>

<xsl:template match="htmlpart">
    <!-- <div class="marker">HTML Part (decoded to text):</div> -->
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="textpart">
    <!-- <div class="marker">Plain Text Part:</div> -->
    <pre>
    <xsl:apply-templates/>
    </pre>
</xsl:template>

<xsl:template match="*|@*">
  <xsl:copy>
   <xsl:apply-templates select="@*"/>
   <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template name="truncate-string">
    <xsl:choose>
        <xsl:when test="string-length($string) > $length">
            <xsl:value-of select="concat(substring($string, 1, ($length - 3)), '...')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$string"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
