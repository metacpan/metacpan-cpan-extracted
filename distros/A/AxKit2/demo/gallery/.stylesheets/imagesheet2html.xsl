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

$Id: imagesheet2html.xsl,v 1.11 2004/02/26 11:48:51 nik Exp $
-->
 
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:dc="http://dublincore.org/documents/2003/02/04/dces/"
  xmlns:exif="http://impressive.net/people/gerald/2001/exif#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/"
  xmlns:aag="http://search.cpan.org/~nikc/AxKit-App-Gallery/xml#"
  xmlns:img="http://www.cpan.org/authors/id/G/GA/GAAS/#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:filelist="http://axkit.org/2002/filelist"
  xmlns:lookup="lookup.uri"
  xmlns:exslt="http://exslt.org/common"
  version="1.0">

  <xsl:include href="breadcrumb.xsl"/>
  
  <xsl:param name="next"/>
  <xsl:param name="prev"/>
  
  <xsl:variable name="thisURI">
    <xsl:for-each select="/imagesheet/image/uri/component">
      <xsl:text>/</xsl:text>
      <xsl:value-of select="u"/>
    </xsl:for-each>
    <xsl:text>?format=html</xsl:text>
  </xsl:variable>

  <xsl:variable name="currentSize" select="/imagesheet/config/perl-vars/GallerySizes/size[@type='default']"/>

  <!-- Map EXIF field values back to useful names.  Some day this will be
       split out in to separate files, chosen at run time, to make l10n
       that much easier.  But not today... -->
  <lookup:flash value="0">Flash did not fire</lookup:flash>
  <lookup:flash value="1">Flash fired</lookup:flash>
  <lookup:flash value="5">Strobe return light not detected</lookup:flash>
  <lookup:flash value="7">Strobe return light detected</lookup:flash>
  <lookup:flash value="9">Flash fired</lookup:flash> <!-- XXX DImage 7i value -->

  <xsl:template match="/">
  <xsl:param name="filename" select="/imagesheet/image/filename/text()"/>

    <html>
      <head>
        <title>Next: <xsl:value-of select="$next"/> Imagesheet for <xsl:value-of select="$filename"/></title>
	<link rel="stylesheet" type="text/css" href="/stylesheets/default.css"/>
      </head>

      <body>
	<div id="header">
        <xsl:call-template name="breadcrumb">
          <xsl:with-param name="nodes" select="/imagesheet/image/uri/component"/>
        </xsl:call-template>
	</div>
        
	<div id="content">
	<div class="picture">
        <p align="center"><img>
	  <xsl:attribute name="src"><xsl:value-of select="/imagesheet/image/filename"/>?format=raw;size=<xsl:value-of select="$currentSize"/></xsl:attribute>
          <xsl:choose>
            <xsl:when test="$currentSize='full'">
              <xsl:attribute name="height"><xsl:value-of select="//rdf:Description/exif:ImageHeight"/></xsl:attribute>
              <xsl:attribute name="width"><xsl:value-of select="//rdf:Description/exif:ImageWidth"/></xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="height"><xsl:value-of select="//foaf:thumbnail[rdf:Description/aag:size = ancestor::image/size]/rdf:Description/img:height"/></xsl:attribute>
              <xsl:attribute name="width"><xsl:value-of select="//foaf:thumbnail[rdf:Description/aag:size = ancestor::image/size]/rdf:Description/img:width"/></xsl:attribute>
            </xsl:otherwise>
          </xsl:choose></img></p>
	</div>
   
	<p align="center">Sizes: 
	  <xsl:for-each select="/imagesheet/config/perl-vars/GallerySizes/size">

	    <xsl:if test="not(@type = 'thumb')">
	      [ <xsl:choose>
                  <xsl:when test=". = /imagesheet/image/size">
                    <xsl:value-of select="."/>
                  </xsl:when>
                  <xsl:when test=". = 'full'">
                    <a href="{/imagesheet/image/filename}?format=raw;size=full">full</a>
                  </xsl:when>
                  <xsl:otherwise>
                    <a><xsl:attribute name="href"><xsl:value-of select="concat($thisURI, ';size=', .)"/></xsl:attribute><xsl:value-of select="."/></a>
                  </xsl:otherwise>
                </xsl:choose> ]
	    </xsl:if>
	  </xsl:for-each>
	</p>

	<table class="bottom" align="center" width="*">
	<tr>
	<td align="left" valign="top">
          <xsl:if test="$prev">
              <a href="{$prev}?format=html;size={$currentSize}"><img src="{$prev}?format=raw;size=thumb"/></a>
          </xsl:if>
    </td>
	<td valign="top">
	<table class="info" align="center">
          <xsl:if test="//exif:DateTimeOriginal">
            <tr>
              <th align="right">Picture Taken:</th>
              <td><xsl:value-of select="//exif:DateTimeOriginal"/></td>
            </tr>
          </xsl:if>

          <xsl:if test="//exif:ExposureTime">
            <!-- Get the focal length, so it can be formatted later -->
            <xsl:variable name="FocalLength" select="//exif:FocalLength"/>
            <!-- Old way of getting this...
              <xsl:call-template name="norm-frac">
                <xsl:with-param name="str" select="
              </xsl:call-template>
            </xsl:variable>
            -->

            <tr>
              <th align="right">Exposure:</th>
               <td>
                 <!-- Format the focal length -->
                 <xsl:value-of select="$FocalLength"/> at
                 <!-- Use the fractional exposure time if the denominator is not 1, 
                      otherwise use the numerator -->
                 <xsl:choose>
                   <xsl:when test="substring-after(//exif:ExposureTime, '/') = 1">
                     <xsl:value-of select="substring-before(//exif:ExposureTime, '/')"/>
                   </xsl:when>
                   <xsl:otherwise>
                     <xsl:value-of select="//exif:ExposureTime"/>
                   </xsl:otherwise>
                 </xsl:choose> sec<xsl:text/> 
                 <!-- Convert the F number to a decimal -->
                 <xsl:text>, </xsl:text>F<xsl:value-of select="//exif:FNumber"/>
                 <!-- The exposure program ('program', 'manual', etc) -->
		 <xsl:if test="//exif:ExposureProgram">
                   <xsl:text>, </xsl:text>
                   <xsl:value-of select="//exif:ExposureProgram"/>
                 </xsl:if>
               </td>
             </tr>
           </xsl:if>

           <xsl:if test="//exif:Flash">
             <tr>
               <th align="right">Flash?</th>
               <xsl:choose>
                 <xsl:when test="document('')/xsl:stylesheet/lookup:flash[@value=//exif:Flash]">
                   <td><xsl:value-of select="document('')/xsl:stylesheet/lookup:flash[@value=//exif:Flash]"/></td>
                 </xsl:when>
                 <!-- If we don't recognise the value, use the Flash value as
                      is.  The Canon EOS10D puts in a text string, rather 
                      than a value -->
                 <xsl:otherwise>
                   <td><xsl:value-of select="//exif:Flash"/></td>
                 </xsl:otherwise>
               </xsl:choose>
             </tr>
           </xsl:if>

          <xsl:choose>
            <xsl:when test="//exif:ISO1">
            <tr>
              <th align="right">ISO:</th>
              <td><xsl:value-of select="//exif:ISO1"/></td>
            </tr>
            </xsl:when>
            <xsl:when test="//exif:ISO">
            <tr>
              <th align="right">ISO:</th>
              <td><xsl:value-of select="//exif:ISO"/></td>
            </tr>
            </xsl:when>
          </xsl:choose>

          <xsl:if test="//exif:ImageWidth and //exif:ImageHeight and //image/filesize">
            <tr>
              <th align="right">Full Size:</th>
              <td><xsl:value-of select="//exif:ImageWidth"/> x <xsl:value-of select="//exif:ImageHeight"/>, <xsl:value-of select="format-number((//image/filesize div 1024), '#,##0')"/>K</td>
            </tr>
          </xsl:if>

          <xsl:if test="//exif:Make">
            <tr>
              <th align="right">Camera:</th>
              <td><xsl:value-of select="//exif:Make"/>, <xsl:value-of select="//exif:Model"/></td>
            </tr>
          </xsl:if>

          <xsl:if test="//exif:Lens">
            <tr>
              <th align="right">Lens:</th>
              <td><xsl:value-of select="//exif:Lens"/></td>
            </tr>
          </xsl:if>

          <xsl:if test="//exif:AFPoint">
            <tr>
              <th align="right">Focus Point:</th>
              <td><xsl:value-of select="//exif:AFPoint"/></td>
            </tr>
          </xsl:if>

          <xsl:if test="//exif:WhiteBalance">
            <tr>
              <th align="right">White Balance:</th>
              <td><xsl:value-of select="//exif:WhiteBalance"/></td>
            </tr>
          </xsl:if>

	</table>
	</td>
	<td align="right" valign="top">
          <xsl:if test="$next">
              <a href="{$next}?format=html;size={$currentSize}"><img src="{$next}?format=raw;size=thumb"/></a>
          </xsl:if>
	</td>
	</tr>
	</table>
	</div>
	
	<div id="footer">
        <div class="createdwith">Created with <a href="http://search.cpan.org/~nikc/AxKit-App-Gallery/">AxKit::App::Gallery</a></div>
	</div>
      </body>
    </html>
  </xsl:template>

  <xsl:template name="norm-frac">
    <xsl:param name="str"/>

    <xsl:variable name="num" select="substring-before($str, '/')"/>
    <xsl:variable name="den" select="substring-after($str, '/')"/>

    <xsl:choose>
      <xsl:when test="$den = 1">
        <xsl:value-of select="$num"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$num div $den"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="nextprev" match="*">
    <xsl:param name="filename"/>
    NextPrev template applied <xsl:value-of select="following-sibling::filelist:file[text() = $filename][last()]"/>
    <!-- <xsl:value-of select="[following-sibling::filelist:file/text() = $filename][last()]"/> -->
  </xsl:template>

  <xsl:template mode="filelist" match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="filelist" select="*|node()"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
