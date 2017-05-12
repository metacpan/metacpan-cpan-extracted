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

$Id: breadcrumb.xsl,v 1.2 2004/02/26 11:58:50 nik Exp $
-->
 
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:dc="http://dublincore.org/documents/2003/02/04/dces/"
  xmlns:exif="http://impressive.net/people/gerald/2001/exif#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/"
  xmlns:aag="http://search.cpan.org/~nikc/AxKit-App-Gallery/xml#"
  xmlns:img="http://www.cpan.org/authors/id/G/GA/GAAS/#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:lookup="lookup.uri"
  version="1.0">

  <xsl:template name="breadcrumb">
    <xsl:param name="nodes"/>

    <div class="breadcrumbs"><a href="/">root</a> :
    <xsl:for-each select="$nodes">
      <xsl:choose>
        <xsl:when test="position() != last()">
          <a>
            <xsl:attribute name="href">
              <xsl:for-each select="./preceding-sibling::component">
                <xsl:text>/</xsl:text><xsl:value-of select="u"/>
              </xsl:for-each>
              <xsl:text>/</xsl:text><xsl:value-of select="u"/>/<xsl:text/>
            </xsl:attribute>
            <xsl:value-of select="u"/>
          </a> :
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="u"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </div>
</xsl:template>
</xsl:stylesheet>
