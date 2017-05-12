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

$Id: mergeimageinfo.xsl,v 1.3 2003/10/19 20:11:34 nik Exp $
-->
 
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  version="1.0">

  <xsl:variable name="cachedir" select="//config/perl-vars/var[@name='GalleryCache']"/>

  <!-- XXX Assumes that the only thing that might need URI escaping is 
       the full path to the file (which might contain things like spaces).
       Will fail to do the right thing if the cache root or the filename
       contains spaces. -->
  <xsl:template match="image">
    <xsl:variable name="imageinfo">
      <xsl:text>file://</xsl:text>
      <xsl:value-of select="$cachedir"/>
      <xsl:call-template name="url-encode">
        <xsl:with-param name="str" select="dirpath"/>
      </xsl:call-template>
      <xsl:text>/</xsl:text>
      <xsl:value-of select="filename"/>
      <xsl:text>/imageinfo.rdf</xsl:text>
    </xsl:variable>
    
    <image>
      <xsl:copy-of select="*|@*|node()"/>
      <xsl:copy-of select="document($imageinfo)"/>
    </image>
  </xsl:template>

  <xsl:template match="*|@*">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Following taken from http://skew.org/xml/stylesheets/url-encode/ -->

  <!-- ISO-8859-1 based URL-encoding demo
       Written by Mike J. Brown, mike@skew.org.
       Updated 2002-05-20.

       No license; use freely, but credit me if reproducing in print.

       Also see http://skew.org/xml/misc/URI-i18n/ for a discussion of
       non-ASCII characters in URIs.
  -->

  <!-- Characters we'll support.
       We could add control chars 0-31 and 127-159, but we won't. -->
  <xsl:variable name="ascii"> !"#$%&amp;'()*+,-./0123456789:;&lt;=&gt;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~</xsl:variable>
  <xsl:variable name="latin1">&#160;&#161;&#162;&#163;&#164;&#165;&#166;&#167;&#168;&#169;&#170;&#171;&#172;&#173;&#174;&#175;&#176;&#177;&#178;&#179;&#180;&#181;&#182;&#183;&#184;&#185;&#186;&#187;&#188;&#189;&#190;&#191;&#192;&#193;&#194;&#195;&#196;&#197;&#198;&#199;&#200;&#201;&#202;&#203;&#204;&#205;&#206;&#207;&#208;&#209;&#210;&#211;&#212;&#213;&#214;&#215;&#216;&#217;&#218;&#219;&#220;&#221;&#222;&#223;&#224;&#225;&#226;&#227;&#228;&#229;&#230;&#231;&#232;&#233;&#234;&#235;&#236;&#237;&#238;&#239;&#240;&#241;&#242;&#243;&#244;&#245;&#246;&#247;&#248;&#249;&#250;&#251;&#252;&#253;&#254;&#255;</xsl:variable>

  <!-- Characters that usually don't need to be escaped -->
  <xsl:variable name="safe">!'()*-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~</xsl:variable>

  <xsl:variable name="hex" >0123456789ABCDEF</xsl:variable>

  <xsl:template name="url-encode">
    <xsl:param name="str"/>   
    <xsl:if test="$str">
      <xsl:variable name="first-char" select="substring($str,1,1)"/>
      <xsl:choose>
        <xsl:when test="contains($safe,$first-char)">
          <xsl:value-of select="$first-char"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="codepoint">
            <xsl:choose>
              <xsl:when test="contains($ascii,$first-char)">
                <xsl:value-of select="string-length(substring-before($ascii,$first-char)) + 32"/>
              </xsl:when>
              <xsl:when test="contains($latin1,$first-char)">
                <xsl:value-of select="string-length(substring-before($latin1,$first-char)) + 160"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:message terminate="no">Warning: string contains a character that is out of range! Substituting "?".</xsl:message>
                <xsl:text>63</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
        <xsl:variable name="hex-digit1" select="substring($hex,floor($codepoint div 16) + 1,1)"/>
        <xsl:variable name="hex-digit2" select="substring($hex,$codepoint mod 16 + 1,1)"/>
        <xsl:value-of select="concat('%',$hex-digit1,$hex-digit2)"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="string-length($str) &gt; 1">
        <xsl:call-template name="url-encode">
          <xsl:with-param name="str" select="substring($str,2)"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
