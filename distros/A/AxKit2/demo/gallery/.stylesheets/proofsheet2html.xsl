<?xml version="1.0" encoding="ISO-8859-1" ?>

<!--
Copyright (c) 2003 Nik Clayton
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

$Id: proofsheet2html.xsl,v 1.7 2004/02/26 11:58:50 nik Exp $
-->
 
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:exif="http://impressive.net/people/gerald/2001/exif#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/"
  xmlns:aag="http://search.cpan.org/~nikc/AxKit-App-Gallery/xml#"
  xmlns:img="http://www.cpan.org/authors/id/G/GA/GAAS/#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:aagfun="urn:ax-app-gallery"
  version="1.0">

  <xsl:include href="breadcrumb.xsl"/>

  <xsl:variable name="totalColumns" select="/proofsheet/config/perl-vars/var[@name='ProofsheetColumns']"/>

  <xsl:template match="/">
    <html>
      <head>
	<title>Proofsheet for:<xsl:text/>
          <xsl:for-each select="/proofsheet/albums/album[name = '.']/uri/component/u">
            <xsl:text/> / <xsl:value-of select="."/>
          </xsl:for-each>
          <xsl:text/> (page <xsl:value-of select="//pages/page[@current]/@number"/>)
        </title>
	<link rel="stylesheet" type="text/css" href="/stylesheets/default.css"/>
      </head>

      <body>
	<div id="header">
        <xsl:call-template name="breadcrumb">
          <xsl:with-param name="nodes" select="/proofsheet/uri/component"/>
        </xsl:call-template>

        <xsl:apply-templates select="/proofsheet/pages"/>
	</div>

	<div id="content">
	<xsl:apply-templates select="//albums"/>

        <xsl:apply-templates select="/proofsheet/images"/>
	</div>
	
	<div id="footer">
	<table border="0" cellspacing="0" cellpadding="0" width="100%"><tr>
        <td align="left"><xsl:apply-templates
        select="/proofsheet/pages"/></td>
	<td align="right">Created with <a href="http://search.cpan.org/~nikc/AxKit-App-Gallery/">AxKit::App::Gallery</a>.</td>
        </tr></table>
	</div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="pages">
    <xsl:if test="count(page) > 1">
      <div class="pages"><b>Pages:</b><xsl:text> </xsl:text>
      <xsl:if test="not(page[1]/@current)"><a href=".?cur_page={number(./page[@current]/@number) - 1}">&lt;&lt;Prev</a><xsl:text> </xsl:text></xsl:if>
      <xsl:apply-templates select="page"/>
      <xsl:if test="not(page[last()]/@current)"><xsl:text> </xsl:text><a href=".?cur_page={number(./page[@current]/@number) + 1}">Next&gt;&gt;</a></xsl:if>
      </div>
    </xsl:if>
  </xsl:template>

  <xsl:template match="page">
    <xsl:variable name="pagenum" select="@number"/>
    <xsl:choose>
      <xsl:when test="@current"><xsl:value-of select="$pagenum"/></xsl:when>
      <xsl:otherwise>
        <a href=".?cur_page={$pagenum}"><xsl:value-of select="$pagenum"/></a>
      </xsl:otherwise>
    </xsl:choose><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="albums">
    <xsl:variable name="albums" select="album[name != '.']"/>
    <xsl:if test="//pages/page[@number = 1]/@current">
    <table class="centered">
      <xsl:for-each select="$albums[position() mod $totalColumns = 1]">
        <tr>
          <xsl:for-each select="self::album |
                following-sibling::album[$totalColumns > position()]">
            <xsl:variable name="dir" select="name"/>
            <xsl:variable name="date" select="aagfun:epoch-to-date(ctime)"/>
            <td align="center" valign="middle">
              <span class="album"><a href="{$dir}/"><img class="icon" src="/icons/folder.gif"/><br/><xsl:text> </xsl:text>
              <xsl:value-of select="$dir"/></a></span></td>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>
    </xsl:if>
  </xsl:template>

  <xsl:template match="images">
    <a name="images"></a>
    <table width="75%" align="center" cellpadding="4">
      <xsl:for-each select="image[position() mod $totalColumns = 1]">
	<tr>
          <xsl:for-each select="self::image | 
		following-sibling::image[$totalColumns > position()]">
            <td align="center" valign="middle"><xsl:apply-templates select="."/></td>
          </xsl:for-each>
        </tr>

        <tr>
          <xsl:for-each select="self::image | 
                following-sibling::image[$totalColumns > position()]">
            <td align="center"><small><xsl:value-of select="filename"/></small></td>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>

    <xsl:if test="./file">
    <table width="75%" align="center" cellpadding="4">
      <tr><th align="left">Other Files</th></tr>
      <xsl:for-each select="file">
        <tr>
          <xsl:apply-templates select="."/>
	</tr>
      </xsl:for-each>
    </table>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="file">
    <td><a href="{filename}"><xsl:value-of select="filename"/></a></td>
  </xsl:template>

  <xsl:template match="image">
    <xsl:variable name="thumbSize" select="/proofsheet/config/perl-vars/GallerySizes/size[@type = 'thumb']"/>

    <xsl:variable name="height">
      <xsl:value-of select="rdf:RDF/rdf:Description/foaf:thumbnail[rdf:Description/aag:size = $thumbSize]/rdf:Description/img:height"/>
    </xsl:variable>

    <xsl:variable name="width">
      <xsl:value-of select="rdf:RDF/rdf:Description/foaf:thumbnail[rdf:Description/aag:size = $thumbSize]/rdf:Description/img:width"/>
    </xsl:variable>
          
    <p><a>
        <xsl:attribute name="href"><xsl:value-of select="filename"/>?format=html</xsl:attribute>
        <img>
          <xsl:attribute name="src"><xsl:value-of select="filename"/>?format=raw;size=thumb</xsl:attribute>

          <xsl:attribute name="border">0</xsl:attribute>

          <xsl:if test="$height">
            <xsl:attribute name="height">
              <xsl:value-of select="$height"/>
            </xsl:attribute>
          </xsl:if>

          <xsl:if test="$width">
            <xsl:attribute name="width">
              <xsl:value-of select="$width"/>
            </xsl:attribute>
          </xsl:if>
        </img>
      </a>
    </p>
  </xsl:template>

</xsl:stylesheet>
