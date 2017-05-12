<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html" indent="yes"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <style type="text/css">html,body{background:#ffc;font-family:helvetica,arial,sans-serif;font-size:0.8em}caption,thead{background:#700;color:#fff}caption,thead th{margin:0;padding:2px}a{color:#a00}a:hover{color:#aaa}.tr1{background:#ffd}.tr2{background:#ffb}tr{vertical-align:top}</style>
        <title>ProServer: Features for <xsl:value-of select="/DASGFF/GFF/@href"/></title></head>
      <body>
        <div id="header"><h4>ProServer: Features for <xsl:value-of select="/DASGFF/GFF/@href"/></h4></div>
        <div id="mainbody">
          <p>Format:
            <input type="radio" name="format" onclick="document.getElementById('table').style.display='block';document.getElementById('xml').style.display='none';" value="Table" checked="checked"/>Table
            <input type="radio" name="format" onclick="document.getElementById('xml').style.display='block';document.getElementById('table').style.display='none';" value="XML"/>XML
          </p>
          <div id="table" style="display:block;">
            <xsl:apply-templates select="/DASGFF/GFF/SEGMENT" mode="table"/>
          </div>
          <div id="xml" style="font-family:courier;display:none;">
            <xsl:apply-templates select="*" mode="xml-main"/>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="SEGMENT" mode="table">
    <table class="z">
      <xsl:attribute name="id">data_<xsl:value-of select="@id"/></xsl:attribute>
      <caption>
        Features for segment 
        <xsl:choose>
          <xsl:when test="@start and @end">
            <xsl:value-of select="@id"/>:<xsl:value-of select="@start"/>,<xsl:value-of select="@end"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@id"/>
          </xsl:otherwise>
        </xsl:choose>
      </caption>
      <thead>
        <tr>
          <th>Label</th>
          <th>Start</th>
          <th>End</th>
          <th>Orientation</th>
          <th>Type</th>
          <th>Method</th>
          <th>Notes</th>
          <th>Links</th>
          <th>Parts</th>
        </tr>
      </thead>
      <tbody>
    <xsl:for-each select="FEATURE">
      <xsl:sort select="@id"/>
      <tr>
        <td><xsl:choose><xsl:when test="@label != ''"><xsl:value-of select="@label"/></xsl:when><xsl:otherwise><xsl:value-of select="@id"/></xsl:otherwise></xsl:choose></td>
        <td><xsl:value-of select="START"/></td>
        <td><xsl:value-of select="END"/></td>
        <td><xsl:value-of select="ORIENTATION"/></td>
        <td><xsl:choose><xsl:when test="TYPE != ''"><xsl:value-of select="TYPE"/></xsl:when><xsl:otherwise><xsl:value-of select="TYPE/@id"/></xsl:otherwise></xsl:choose></td>
        <td><xsl:choose><xsl:when test="METHOD != ''"><xsl:value-of select="METHOD"/></xsl:when><xsl:otherwise><xsl:value-of select="METHOD/@id"/></xsl:otherwise></xsl:choose></td>
        <td><xsl:apply-templates select="NOTE"/></td>
        <td><xsl:if test="LINK"><xsl:apply-templates select="LINK"/></xsl:if></td>
        <td><xsl:apply-templates select="PART"/></td>
      </tr>
    </xsl:for-each>
    </tbody>
    </table>
  </xsl:template>
  <xsl:template match="PART">
    <xsl:variable name="part_id" select="@id" />
    <xsl:variable name="part_el" select="../../FEATURE[@id=$part_id]" />
    <xsl:choose><xsl:when test="$part_el/@label != ''"><xsl:value-of select="$part_el/@label"/></xsl:when><xsl:otherwise><xsl:value-of select="$part_el/@id"/></xsl:otherwise></xsl:choose>
    <xsl:if test="position()!=last()"><br/></xsl:if>
  </xsl:template>
  <xsl:template match="NOTE">
    <xsl:value-of select="."/>
    <xsl:if test="position()!=last()"><br/></xsl:if>
  </xsl:template>
  <xsl:template match="LINK">
    [<a><xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
      <xsl:choose>
        <xsl:when test="text()"><xsl:value-of select="text()" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="@href" /></xsl:otherwise>
      </xsl:choose>
    </a>]
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
