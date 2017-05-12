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

$Id: proofsheet2rss.xsl,v 1.2 2004/02/26 11:58:50 nik Exp $
-->
 
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:exif="http://impressive.net/people/gerald/2001/exif#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/"
  xmlns:aag="http://search.cpan.org/~nikc/AxKit-App-Gallery/xml#"
  xmlns:img="http://www.cpan.org/authors/id/G/GA/GAAS/#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dc="http://dublincore.org/documents/2003/06/02/dces/"
  version="1.0">

  <xsl:variable name="totalColumns" select="/proofsheet/config/perl-vars/var[@name='ProofsheetColumns']"/>

  <xsl:variable name="thumbSize" select="/proofsheet/config/perl-vars/GallerySizes/size[@type = 'thumb']"/>

  <xsl:variable name="site" select="//config/server/site"/>

  <xsl:template match="/">
    <rdf:RDF>
      <channel rdf:about="">
        <title>Proofsheet for: <xsl:value-of select="//config/server/hostname"/>:<xsl:value-of select="//config/server/port"/>
      </title>
      <description>Never was one for descriptions</description>
      <link></link>
      <items>
        <rdf:Seq>

          <!-- XXX This is a pain.  These loops are identical except for the
               final xsl:value-of.  Should be possible to refactor this. -->

          <xsl:for-each select="//album[name != '.']">
            <rdf:li>
              <xsl:attribute name="rdf:resource">
                <xsl:value-of select="$site"/>
                <xsl:text>/</xsl:text>
                <xsl:for-each select="uri/component">
                  <xsl:value-of select="e"/>
                  <xsl:text>/</xsl:text>
                </xsl:for-each>
                <xsl:value-of select="name"/>
              </xsl:attribute>
            </rdf:li>
          </xsl:for-each>

          <xsl:for-each select="//image">
            <rdf:li>
              <xsl:attribute name="rdf:resource">
                <xsl:value-of select="$site"/>
                <xsl:text>/</xsl:text>
                <xsl:for-each select="uri/component">
                  <xsl:value-of select="e"/>
                  <xsl:text>/</xsl:text>
                </xsl:for-each>
                <xsl:value-of select="filename"/>
              </xsl:attribute>
            </rdf:li>
          </xsl:for-each>
        </rdf:Seq>
      </items>
    </channel>
    
    <!-- XXX Again, lots of code duplication here that should be fixed -->
    <xsl:for-each select="//album[name != '.']">
      <xsl:variable name="fullurl">
        <xsl:value-of select="$site"/>
        <xsl:text>/</xsl:text>
        <xsl:for-each select="uri/component">
          <xsl:value-of select="e"/>
          <xsl:text>/</xsl:text>
        </xsl:for-each>
      </xsl:variable>

      <item>
        <xsl:attribute name="rdf:about">
          <xsl:value-of select="$fullurl"/>
          <xsl:value-of select="name"/>
          <xsl:text>/</xsl:text>
        </xsl:attribute>

        <link><xsl:value-of select="$fullurl"/><xsl:value-of select="name"/><xsl:text>/</xsl:text>
        </link>
        
        <!-- This should be a brief (10 words max) description of the 
             directory -->
        <title><xsl:value-of select="name"/></title>

        <!-- A longer description -->
        <description><xsl:value-of select="name"/></description>

        <!-- No thumbnails for a directory (yet!) -->
        <!--
        <foaf:thumbnail>
          <xsl:attribute name="rdf:resource">
            <xsl:value-of select="$site"/>
            <xsl:value-of select="rdf:RDF/rdf:Description/foaf:thumbnail[rdf:Description/aag:size = $thumbSize]/rdf:Description/@rdf:about"/>
          </xsl:attribute>
        </foaf:thumbnail>
        -->

        <!-- No useful date info for a directory -->
        <!--
        <xsl:if test="rdf:RDF/rdf:Description/exif:DateTimeDigitized">
          <dc:date><xsl:value-of select="rdf:RDF/rdf:Description/exif:DateTimeDigitized"/></dc:date>
        </xsl:if>
        -->
      </item>      
    </xsl:for-each>

    <xsl:for-each select="//image">
      <xsl:variable name="fullurl">
        <xsl:value-of select="$site"/>
        <xsl:text>/</xsl:text>
        <xsl:for-each select="uri/component">
          <xsl:value-of select="e"/>
          <xsl:text>/</xsl:text>
        </xsl:for-each>
      </xsl:variable>

      <item>
        <xsl:attribute name="rdf:about">
          <xsl:value-of select="$fullurl"/>
          <xsl:value-of select="filename"/>
        </xsl:attribute>

        <link><xsl:value-of select="$fullurl"/><xsl:value-of select="filename"/>
        </link>
        
        <!-- This should be a brief (10 words max) description of the image -->
        <title><xsl:value-of select="filename"/></title>

        <!-- A longer description -->
        <description><xsl:value-of select="filename"/></description>

        <foaf:thumbnail>
          <xsl:attribute name="rdf:resource">
            <xsl:value-of select="$site"/>
            <xsl:value-of select="rdf:RDF/rdf:Description/foaf:thumbnail[rdf:Description/aag:size = $thumbSize]/rdf:Description/@rdf:about"/>
          </xsl:attribute>
        </foaf:thumbnail>

        <xsl:if test="rdf:RDF/rdf:Description/exif:DateTimeDigitized">
          <dc:date><xsl:value-of select="rdf:RDF/rdf:Description/exif:DateTimeDigitized"/></dc:date>
        </xsl:if>
      </item>
    </xsl:for-each>
  </rdf:RDF>
</xsl:template>
</xsl:stylesheet>
