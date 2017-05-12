<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">
  <xsl:output method="xml" version="1.0" indent="no" standalone="no" omit-xml-declaration="no"
    media-type="text/html"
    encoding="UTF-8"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <style type="text/css">html,body{background:#ffc;font-family:helvetica,arial,sans-serif;font-size:0.8em}thead{background:#700;color:#fff}thead th{margin:0;padding:2px}a{color:#a00}a:hover{color:#aaa}.tr1{background:#ffd}.tr2{background:#ffb}tr{vertical-align:top}</style>
        <title>ProServer: Sequence</title>
      </head>
      <body>
        <div id="header"><h4>ProServer: Sequence</h4></div>
        <div id="mainbody">
          <p>Format:
            <input type="radio" name="format" onclick="document.getElementById('numbered').style.display='block';document.getElementById('fasta').style.display='none';document.getElementById('xml').style.display='none';" value="Numbered" checked="checked"/>Numbered
            <input type="radio" name="format" onclick="document.getElementById('fasta').style.display='block';document.getElementById('numbered').style.display='none';document.getElementById('xml').style.display='none';" value="Fasta"/>Fasta
            <input type="radio" name="format" onclick="document.getElementById('xml').style.display='block';document.getElementById('numbered').style.display='none';document.getElementById('fasta').style.display='none';" value="XML"/>XML
          </p>
          <div id="numbered" style="font-family:courier;display:block;">
            <xsl:apply-templates select="*/SEQUENCE" mode="numbered"/>
          </div>
          <div id="fasta" style="font-family:courier;display:none;">
            <xsl:apply-templates select="*/SEQUENCE" mode="fasta"/>
          </div>
          <div id="xml" style="font-family:courier;display:none;">
            <xsl:apply-templates select="*" mode="xml-main"/>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="SEQUENCE" mode="fasta">
    <xsl:variable name="start">
      <xsl:choose><xsl:when test="@start"><xsl:value-of select="@start"/></xsl:when><xsl:otherwise>1</xsl:otherwise></xsl:choose>
    </xsl:variable>
    <xsl:variable name="seq">
      <xsl:choose><xsl:when test="DNA"><xsl:value-of select="translate(normalize-space(DNA/text()),' ','')"/></xsl:when><xsl:otherwise><xsl:value-of select="translate(normalize-space(text()),' ','')"/></xsl:otherwise></xsl:choose>
    </xsl:variable>
    <xsl:variable name="stop" select="$start + string-length($seq) -1"/>
    <div>
      &gt;<xsl:value-of select="@id"/>:<xsl:value-of select="$start"/>,<xsl:value-of select="$stop"/>
      <xsl:if test="@version">|<xsl:value-of select="@version"/></xsl:if><br/>
      <xsl:call-template name="writeseq">
        <xsl:with-param name="seq" select="$seq"/>
      </xsl:call-template>
    </div>
  </xsl:template>
  <xsl:template match="SEQUENCE" mode="numbered">
    <xsl:variable name="pos">
      <xsl:choose><xsl:when test="@start"><xsl:value-of select="@start"/></xsl:when><xsl:otherwise>1</xsl:otherwise></xsl:choose>
    </xsl:variable>
    <xsl:variable name="seq">
      <xsl:choose><xsl:when test="DNA"><xsl:value-of select="translate(normalize-space(DNA/text()),' ','')"/></xsl:when><xsl:otherwise><xsl:value-of select="translate(normalize-space(text()),' ','')"/></xsl:otherwise></xsl:choose>
    </xsl:variable>
    <table>
      <thead>
        <tr><th colspan="3"><xsl:value-of select="@id"/><xsl:if test="@version"> version <xsl:value-of select="@version"/></xsl:if></th></tr>
      </thead>
      <tbody>
        <xsl:call-template name="writeseq">
          <xsl:with-param name="seq" select="$seq"/>
          <xsl:with-param name="pos" select="$pos"/>
        </xsl:call-template>
      </tbody>
    </table>
    <br/>
  </xsl:template>
  <xsl:template name="writeseq">
    <xsl:param name="seq"/>
    <xsl:param name="pos"/>
    <xsl:choose>
      <xsl:when test="string-length($seq) > 80">
        <xsl:call-template name="writeseq">
          <xsl:with-param name="seq" select="substring($seq,1,80)"/>
          <xsl:with-param name="pos"><xsl:if test="$pos>0"><xsl:value-of select="$pos"/></xsl:if></xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="writeseq">
          <xsl:with-param name="seq" select="substring($seq,81)"/>
          <xsl:with-param name="pos"><xsl:if test="$pos>0"><xsl:value-of select="$pos+80"/></xsl:if></xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$pos > 0">
            <tr>
              <td><xsl:value-of select="$pos"/></td>
              <td><xsl:value-of select="$seq"/></td>
              <td><xsl:value-of select="$pos + string-length($seq) -1"/></td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$seq"/><br/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@*" mode="xml-att">
    <span style="color:purple"><xsl:text>&#160;</xsl:text><xsl:value-of select="name()"/>=&quot;</span><span style="color:red"><xsl:value-of select="."/></span><span style="color:purple">&quot;</span>
  </xsl:template>
  
  <xsl:template match="*" mode="xml-main">
    <xsl:choose>
      <xsl:when test="*">
        <span style="color:blue">&lt;<xsl:value-of select="name()"/></span><xsl:apply-templates select="@*" mode="xml-att"/><span style="color:blue">&gt;</span>
        <div style="margin-left: 1em"><xsl:apply-templates select="*" mode="xml-main"/></div>
        <span style="color:blue">&lt;/<xsl:value-of select="name()"/>&gt;</span><br/>
      </xsl:when>
      <xsl:when test="text()">
        <span style="color:blue">&lt;<xsl:value-of select="name()"/></span><xsl:apply-templates select="@*" mode="xml-att"/><span style="color:blue">&gt;</span><xsl:apply-templates select="text()" mode="xml-text"/><span style="color:blue">&lt;/<xsl:value-of select="name()"/>&gt;</span><br/>
      </xsl:when>
      <xsl:otherwise>
        <span style="color:blue">&lt;<xsl:value-of select="name()"/></span><xsl:apply-templates select="@*" mode="xml-att"/><span style="color:blue"> /&gt;</span><br/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="text()" mode="xml-text">
    <div style="margin-left: 1em; color:black"><xsl:value-of select="."/></div>
  </xsl:template>
  
</xsl:stylesheet>