<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output method="html" indent="yes"/>
  <xsl:param name="css"/>

  <!-- accepts both macro and un-macroized chadoxml -->

  <!-- xort macros: index everything with an ID attribute -->
  <xsl:key name="k-macro" match="//*" use="@id"/>

  <xsl:template match="/">
    <html>
      <head>
        <meta http-equiv="Content-Type"
          content="text/html; charset=iso-8859-1" />
        <meta name="GENERATOR" content="chado-feature-summary-html.xsl by Chris Mungall"/>
        <link rel="stylesheet" href="{$css}" type="text/css" />
        <title>
          <xsl:text>Chado Feature Summary</xsl:text>
        </title>
      </head>
      <body>
        <xsl:apply-templates select="chado/feature"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="feature">
    <div class="feature">
      <div class="name"><xsl:value-of select="name"/></div>
      <div class="type">
        <xsl:apply-templates select="type_id"/>
      </div>
      <div class="dbxref-list">
        <xsl:apply-templates select="dbxref_id"/>
      </div>
      <xsl:apply-templates select="residues"/>
      <ul class="featureprop">
        <xsl:apply-templates select="featureprop"/>
      </ul>
      <xsl:apply-templates select="featureloc"/>
      <xsl:if test="feature_relationship">
        <h5>
          <xsl:text>This feature is composed of:</xsl:text>
        </h5>
        <ul class="feature_relationship">
          <xsl:apply-templates select="feature_relationship"/>
        </ul>
      </xsl:if>
    </div>
  </xsl:template>

  <xsl:template match="residues">
    <div class="residues">
      <xsl:apply-templates mode="seq-str" select="substring(.,1)"/>
    </div>
  </xsl:template>

  <xsl:template mode="seq-str" match="node()|text()|*|@*">
    <xsl:choose>
      <xsl:when test="string-length(.) > 20">
        <xsl:value-of select="substring(.,1,20)"/>
        <br/>
        <xsl:apply-templates select="substring(..,20)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="dbxref_id">
    <!-- dbxref is either nested or refered to via a macro -->
    <xsl:choose>
      <xsl:when test="dbxref">
        <xsl:apply-templates select="dbxref"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="key('k-macro',.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="dbxref">
    <span class="dbxref">
      <xsl:apply-templates select="db_id"/>
      <xsl:text>:</xsl:text>
      <xsl:value-of select="accession"/>
    </span>
  </xsl:template>

  <xsl:template match="db_id">
    <!-- db is either nested or refered to via a macro -->
    <xsl:choose>
      <xsl:when test="db">
        <xsl:value-of select="db"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="key('k-macro',.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="type_id">
    <!-- type is either nested or refered to via a macro -->
    <xsl:choose>
      <xsl:when test="cvterm">
        <xsl:value-of select="cvterm/name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="key('k-macro',.)/name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="featureprop">
    <li class="featureprop">
      <span class="featureprop-type">
        <xsl:apply-templates select="type_id"/>
      </span>
      <span class="featureprop-value">
        <xsl:value-of select="value"/>
      </span>
    </li>
  </xsl:template>

  <xsl:template match="featureloc">
    <span class="featureloc">
      <span class="featureloc-key">
        <xsl:text>Location</xsl:text>
      </span>
      <span class="featureloc-srcfeature">
        <xsl:value-of select="srcfeature_id/feature/uniquename"/>
      </span>
        <xsl:text>:</xsl:text>
      <span class="featureloc-coords">
        <xsl:value-of select="fmin+1"/>
        <xsl:text>..</xsl:text>
        <xsl:value-of select="fmax"/>
        <xsl:text>[</xsl:text>
        <xsl:choose>
          <xsl:when test="strand=1">
            <xsl:text>+</xsl:text>
          </xsl:when>
          <xsl:when test="strand=-1">
            <xsl:text>-</xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:text>]</xsl:text>
      </span>
    </span>
  </xsl:template>

  <xsl:template match="feature_relationship">
    <li class="feature_relationship">
      <xsl:apply-templates select="subject_id/feature"/>
    </li>
  </xsl:template>

</xsl:stylesheet>
