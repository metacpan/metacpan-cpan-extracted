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

$Id: filelist2proofsheet.xsl,v 1.1.1.1 2003/03/29 17:11:49 nik Exp $

-->
 
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:f="http://axkit.org/2002/filelist"
  exclude-result-prefixes="f"
  version="1.0">

  <xsl:template match="/">
    <proofsheet>

    <config>
      <!-- Space for information about the configuration used to build this
	   proofsheet -->
    </config>

    <albums>
      <xsl:apply-templates select="//f:directory"/>
    </albums>

    <images>
      <xsl:apply-templates select="//f:file"/>
    </images>
    </proofsheet>
  </xsl:template>

  <xsl:template match="f:directory">
    <album>
      <name><xsl:value-of select="."/></name>
      <ctime><xsl:value-of select="@ctime"/></ctime>
    </album>
  </xsl:template>

  <xsl:template match="f:file">
    <xsl:choose>
      <xsl:when test="contains(text(), '.jpg') or contains(text(), '.JPG')">
    <image>
      <filename><xsl:value-of select="."/></filename>
      <filesize><xsl:value-of select="@size"/></filesize>
      <modified><xsl:value-of select="@mtime"/></modified>
      <navigation>
        <xsl:if test="./preceding-sibling::f:file">
          <prev><xsl:value-of select="preceding-sibling::f:file[1]"/></prev>
        </xsl:if>
        <xsl:if test="./following-sibling::f:file">
          <next><xsl:value-of select="following-sibling::f:file[1]"/></next>
        </xsl:if>
      </navigation>
    </image>
      </xsl:when>
      <xsl:otherwise>
    <file>
      <filename><xsl:value-of select="."/></filename>
      <filesize><xsl:value-of select="@size"/></filesize>
      <modified><xsl:value-of select="@mtime"/></modified>
      <navigation>
        <xsl:if test="./preceding-sibling::f:file">
          <prev><xsl:value-of select="preceding-sibling::f:file[1]"/></prev>
        </xsl:if>
        <xsl:if test="./following-sibling::f:file">
          <next><xsl:value-of select="following-sibling::f:file[1]"/></next>
        </xsl:if>
      </navigation>
    </file>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
