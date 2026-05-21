<?xml version="1.0"?>
<!--
  Modified from BibTeXML: http://bibtexml.sourceforge.net/
  License: http://creativecommons.org/licenses/GPL/2.0/
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:bibtex="http://bibtexml.sf.net/">
  <xsl:output method="text"
              media-type="application/x-bibtex" />
  <xsl:strip-space elements="*"/>

  <!--
      Be adviced that this converter does no validation or
      error checking of the input BibTeXML data, as this is
      assumed to be a valid BibTeXML document instance.
  -->

  <xsl:template match="*">
    <xsl:apply-templates select="bibtex:*"/>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>

  <xsl:template match="bibtex:entry">
    <xsl:text>&#xA;</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="bibtex:entry/bibtex:*">
    <xsl:text>@</xsl:text>
    <xsl:value-of select='substring-after(name(),"bibtex:")'/>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="../@id"/>
    <xsl:text>,</xsl:text>
    <xsl:text>&#xA;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="bibtex:entry/*/bibtex:*">
    <xsl:text>   </xsl:text>
    <xsl:value-of select='substring-after(name(),"bibtex:")'/>
    <xsl:text> = {</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>},</xsl:text>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="bibtex:person">
    <xsl:apply-templates/>
    <xsl:if test="not(position()=last())">
      <xsl:text> and </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="bibtex:person/*">
    <xsl:apply-templates/>
    <xsl:if test="not(position()=last())">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="bibtex:title/bibtex:title|
                       bibtex:chapter/bibtex:title">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="bibtex:title/bibtex:subtitle|
                       bibtex:chapter/bibtex:subtitle">
    <xsl:text>: </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="bibtex:chapter/bibtex:pages">
    <xsl:text>, pp. </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="bibtex:keyword">
    <xsl:apply-templates/>
    <xsl:if test="not(position()=last()-1)">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
