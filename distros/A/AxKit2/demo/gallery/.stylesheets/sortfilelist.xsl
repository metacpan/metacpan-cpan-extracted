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

$Id: sortfilelist.xsl,v 1.1.1.1 2003/03/29 17:11:49 nik Exp $
-->
 
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:f="http://axkit.org/2002/filelist"
  version="1.0">

  <!-- Make sure the directory names are first, the filenames are second,
       and that they are sorted.
 
       Why not just use <xsl:sort> at various other places in the stylesheet
       chain?  Because <xsl:sort> sorts the elements, but doesn't adjust their
       location when using axis specifications.  Since we need to do this later
       to (e.g.) calculate the <next> and <prev> elements, this sorting needs
       to happen early. -->

  <xsl:template match="/">
    <filelist>
      <xsl:apply-templates select="//f:directory">
        <xsl:sort select="."/>
      </xsl:apply-templates>

      <xsl:apply-templates select="//f:file">
        <xsl:sort select="."/>
      </xsl:apply-templates>
    </filelist>
  </xsl:template>

  <xsl:template match="f:directory | f:file">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
