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
  version="1.0">

  <xsl:include href="file:///home/nik/Local-CVS/CPAN/AxKit::App::Gallery/src/stylesheets/breadcrumb.xsl"/>

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
        <style type="text/css">
body {
  background: #cccccc;
}
img {
  border: 1px solid black;
}
        </style>
      </head>

      <body>
        <xsl:call-template name="breadcrumb">
          <xsl:with-param name="nodes" select="/proofsheet/albums/album[name = '.']/uri/component"/>
        </xsl:call-template>
	
        <xsl:apply-templates select="/proofsheet/pages"/>

	<p><xsl:apply-templates select="//albums"/></p>

        <xsl:apply-templates select="/proofsheet/images"/>

        <p align="right"><small>Created with <a href="http://search.cpan.org/~nikc/AxKit-App-Gallery/">AxKit::App::Gallery</a></small></p>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="pages">
    <xsl:if test="count(page) > 1">
      <p><b>Pages:</b><xsl:text> </xsl:text><xsl:apply-templates select="page"/></p>
    </xsl:if>
  </xsl:template>

  <xsl:template match="page">
    <xsl:variable name="pagenum" select="@number"/>
    <xsl:choose>
      <xsl:when test="@current"><xsl:value-of select="$pagenum"/></xsl:when>
      <xsl:otherwise>
        <a>
          <xsl:attribute name="href">.?cur_page=<xsl:value-of select="$pagenum"/></xsl:attribute>
        <xsl:value-of select="$pagenum"/>
        </a></xsl:otherwise>
    </xsl:choose><xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="albums">
    <xsl:variable name="albums" select="album[name != '.']"/>
    <table width="75%" align="center" cellpadding="4">
      <xsl:for-each select="$albums[position() mod $totalColumns = 1]">
        <tr>
          <xsl:for-each select="self::album |
                following-sibling::album[$totalColumns > position()]">
            <xsl:variable name="dir" select="name"/>
            <td align="center" valign="middle">
              <a href="{$dir}/"><xsl:value-of select="$dir"/></a></td>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

  <xsl:template match="images">
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
