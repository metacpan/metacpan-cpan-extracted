<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html" indent="yes"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <style type="text/css">html,body{background:#ffc;font-family:helvetica,arial,sans-serif;font-size:0.8em}caption,thead{background:#700;color:#fff}caption,thead th{margin:0;padding:2px}a{color:#a00}a:hover{color:#aaa}.tr1{background:#ffd}.tr2{background:#ffb}tr{vertical-align:top}</style>
        <title>ProServer: Types for <xsl:value-of select="/DASTYPES/GFF/@href"/></title></head>
      <body>
        <div id="header"><h4>ProServer: Types for <xsl:value-of select="/DASTYPES/GFF/@href"/></h4></div>
        <div id="mainbody">
          <p>Format:
            <input type="radio" name="format" onclick="document.getElementById('table').style.display='block';document.getElementById('xml').style.display='none';" value="Table" checked="checked"/>Table
            <input type="radio" name="format" onclick="document.getElementById('xml').style.display='block';document.getElementById('table').style.display='none';" value="XML"/>XML
          </p>
          <div id="table" style="display:block;">
            <xsl:apply-templates select="/DASTYPES/GFF/SEGMENT" mode="table"/>
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
        Types for segment 
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
          <th>Type ID</th>
          <th>Category</th>
          <th>Ontology Term</th>
          <th>Number of Features</th>
        </tr>
      </thead>
      <tbody>
    <xsl:for-each select="TYPE">
      <xsl:sort select="@id"/>
      <tr>
        <td><xsl:value-of select="@id"/></td>
        <td><xsl:value-of select="@category"/></td>
        <td><xsl:value-of select="@cvId"/></td>
        <td><xsl:value-of select="."/></td>
      </tr>
    </xsl:for-each>
    </tbody>
    </table>
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
