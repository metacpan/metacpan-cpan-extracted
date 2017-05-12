<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html" indent="yes"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head><style type="text/css">html,body{background:#ffc;font-family:helvetica,arial,sans-serif;font-size:0.8em}thead{background:#700;color:#fff}thead th{margin:0;padding:2px}a{color:#a00}a:hover{color:#aaa}.tr1{background:#ffd}.tr2{background:#ffb}tr{vertical-align:top}</style>
<script type="text/javascript"><![CDATA[
addEvent(window,"load",zi);
function zi(){if(!document.getElementsByTagName)return;var ts=document.getElementsByTagName("table");for(var i=0;i!=ts.length;i++){t=ts[i];if(t){if(((' '+t.className+' ').indexOf("z")!=-1))z(t);}}}
function z(t){var tr=1;for(var i=0;i!=t.rows.length;i++){var r=t.rows[i];var p=r.parentNode.tagName.toLowerCase();if(p!='thead'){if(p!='tfoot'){r.className='tr'+tr;tr=1+!(tr-1);}}}}
function addEvent(e,t,f,c){/*Scott Andrew*/if(e.addEventListener){e.addEventListener(t,f,c);return true;}else if(e.attachEvent){var r=e.attachEvent("on"+t,f);return r;}}
function hideColumn(c){var t=document.getElementById('data');var trs=t.getElementsByTagName('tr');for(var i=0;i!=trs.length;i++){var tds=trs[i].getElementsByTagName('td');if(tds.length!=0)tds[c].style.display="none";var ths=trs[i].getElementsByTagName('th');if(ths.length!=0)ths[c].style.display="none";}}
]]></script><title>ProServer: Sources List</title></head>
      <body>
        <div id="header"><h4>ProServer: Source Information</h4></div>
        <div id="mainbody">
          <p>Format:
            <input type="radio" name="format" onclick="document.getElementById('data').style.display='block';document.getElementById('xml').style.display='none';" value="Table" checked="checked"/>Table
            <input type="radio" name="format" onclick="document.getElementById('xml').style.display='block';document.getElementById('data').style.display='none';" value="XML"/>XML
          </p>
          <table class="z" id="data" style="display:block;">
            <thead>
              <tr><th>URI</th><th>Title</th><th>Description</th><th>Contact</th><th>Coordinates</th><th>Capabilities</th><th>Created</th></tr>
            </thead>
            <tbody>
              <xsl:apply-templates select="SOURCES/SOURCE">
                <xsl:sort select="@title"/>
              </xsl:apply-templates>
            </tbody>
          </table>
          <div id="xml" style="font-family:courier;display:none;">
            <xsl:apply-templates select="*" mode="xml-main"/>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="SOURCE">
    <xsl:for-each select="VERSION">
      <xsl:sort select="@uri"/>
      <tr>
        <td><xsl:value-of select="@uri"/></td>
        <td style="white-space:nowrap;"><xsl:value-of select="../@title"/></td>
        <td><xsl:value-of select="../@description"/> [<a><xsl:attribute name="href"><xsl:value-of select="../@doc_href"/></xsl:attribute>More info</a>]</td>
        <td><xsl:value-of select="../MAINTAINER/@email"/></td>
        <td style="white-space:nowrap;"><xsl:apply-templates select="COORDINATES"/></td>
        <td><xsl:apply-templates select="CAPABILITY"/></td>
        <td><xsl:value-of select="@created"/></td>
      </tr>
    </xsl:for-each>
  </xsl:template>
    <xsl:template match="COORDINATES">
    <xsl:value-of select="."/>
    <xsl:if test="position()!=last()"><br/></xsl:if>
  </xsl:template>
  <xsl:template match="CAPABILITY">
    <xsl:variable name="command" select="substring-after( @type,':')"/>
    <xsl:choose>
      <xsl:when test="not(@query_uri)">
        [<xsl:value-of select="@type"/>]
      </xsl:when>
      <xsl:when test="($command='dsn' or $command='entry_points' or $command='stylesheet' or $command='sources')">
        [<a><xsl:attribute name="href"><xsl:value-of select="@query_uri"/></xsl:attribute><xsl:value-of select="@type"/></a>]
      </xsl:when>
      <xsl:when test="($command='alignment')">
        [<a><xsl:attribute name="href"><xsl:value-of select="@query_uri"/>?query=<xsl:value-of select="../COORDINATES[1]/@test_range"/>&amp;subjectcoordsys=<xsl:value-of select="../COORDINATES[2]"/></xsl:attribute><xsl:value-of select="@type"/></a>]
      </xsl:when>
      <xsl:when test="($command='volmap')">
        [<a><xsl:attribute name="href"><xsl:value-of select="@query_uri"/>?query=<xsl:value-of select="../COORDINATES/@test_range"/></xsl:attribute><xsl:value-of select="@type"/></a>]
      </xsl:when>
      <xsl:when test="($command='interaction')">
        [<a><xsl:attribute name="href"><xsl:value-of select="@query_uri"/>?interactor=<xsl:value-of select="../COORDINATES/@test_range"/></xsl:attribute><xsl:value-of select="@type"/></a>]
      </xsl:when>
      <xsl:otherwise>
        [<a><xsl:attribute name="href"><xsl:value-of select="@query_uri"/>?segment=<xsl:value-of select="../COORDINATES/@test_range"/></xsl:attribute><xsl:value-of select="@type"/></a>]
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