<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: changelog2dl.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet transforms ChangeLogML content into a XHTML
    fragment whose top-level element is a "dl". The container is given
    an ID attribute of "changelog-container", and a class that follows in
    the pattern of all the changelog-derived XHTML elements. This container
    differs slightly from the other XHTML fragment-generators, as the
    revision-banner (the pseudo-title text) is made the content of the "dt"
    element, rather than being contained within the main release-div. The
    release-div is the content of the "dd" element, and is identical to the
    release-div of all the other fragment-styles, save for the absence of
    the revision-banner.

    The template recognizes the following input parameters:

    versions
      A list of one or more version-strings against which the @version
      attribute of a release is checked before it is processed. The
      special value "all" (the default value) means to process all
      releases, and the special value "first" means to process only the
      first version seen (sensitive to sorting order).
    order
      Determines the sorting-order for the release blocks. Must be one of
      "ascending" (in which the oldest release is processed first) or
      "descending" (the default, in which the newest release is processed
      first).
-->
<xsl:stylesheet version="1.0"
                xmlns:cl="http://www.blackperl.com/2009/01/ChangeLogML"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml">

  <!--
    This snippet contains most of the core XHTML-generation templates. For this
    stylesheet, use "import" rather than "include" so that we can override the
    template for cl:release.
  -->
  <xsl:import href="common-xhtml.xslt" />

  <!--
    This snippet-file contains common variable declarations (date at the moment,
    the "credits" string to identify the processor) and non-content templates
    such as the date-formatter (which only returns a string, no XHTML or
    plain-text-specific material).
  -->
  <xsl:include href="common.xslt" />

  <xsl:strip-space elements="*" />
  <xsl:output method="xml" indent="no" omit-xml-declaration="yes" />

  <!--
    The "versions" parameter controls which releases go into the output. Valid
    values are "all" (default), "first" or a list of one-or-more specific
    values, comma-separated, that are tested against the "version" attribute of
    each <release> tag/block.
  -->
  <xsl:param name="versions" select="'all'" />

  <!--
    The "order" parameter controls whether the versions are documented in
    ascending order or descending order (the default). Versions are sorted as
    strings, to allow for multiple dots and/or alphabetic characters. Keep this
    in mind before complaining that 0.15 sorted before 0.4...
  -->
  <xsl:param name="order" select="'descending'" />

  <!-- Here is where actual "real" processing begins... -->

  <!--
    For this stylesheet, the desired output is a dl container that itself
    contains all the release-divs (possibly trimmed down by the 'versions'
    parameter) as the dt/dd children. None of the rest of the XHTML boilerplate
    is needed.
  -->
  <xsl:template match="/">
    <xsl:call-template name="insert-comment">
      <xsl:with-param name="id"><![CDATA[$Id: changelog2dl.xslt 8 2009-01-19 06:46:50Z rjray $]]></xsl:with-param>
    </xsl:call-template>
    <dl xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"
        id="changelog-container" class="changelog-container-dl"><xsl:value-of select="$newline" />
      <xsl:for-each select="cl:changelog//cl:release">
        <xsl:sort select="@date" data-type="text" order="{$order}" />
        <xsl:choose>
          <xsl:when test="$versions = 'first'">
            <xsl:if test="position() = 1">
              <xsl:apply-templates select="." />
            </xsl:if>
          </xsl:when>
          <!-- Seems like an odd test, but really just avoids the default
               case of 'all' -->
          <xsl:when test="$versions != '' and $versions != 'all'">
            <xsl:if test="contains(concat(',', $versions, ','), concat(',', @version, ','))">
              <xsl:apply-templates select="." />
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </dl>
  </xsl:template>

  <!--
    This template handles the block for a single release. It uses the value
    of the @version attribute to create a unique ID attribute for the generated
    div, as well as an anchor for the a-tag that wraps the text in the dt.
  -->
  <xsl:template name="release-div" match="cl:release">
    <xsl:variable name="version" select="translate(@version, '.', '_')" />
    <xsl:variable name="div_id" select="concat('release_', $version, '_div')" />
    <xsl:variable name="anchor_id" select="concat('release_', $version)" />
    <dt class="changelog-release-dt"><xsl:value-of select="$newline" />
      <a name="{$anchor_id}"><xsl:text>Version: </xsl:text><xsl:value-of select="@version" /></a><xsl:value-of select="$newline" />
    </dt><xsl:value-of select="$newline" />
    <dd class="changelog-release-dd"><xsl:value-of select="$newline" />
      <div class="changelog-release-div" id="{$div_id}"><xsl:value-of select="$newline" />
        <span class="changelog-release-date">
          Released:
          <span class="changelog-date">
            <xsl:call-template name="format-date">
              <xsl:with-param name="date" select="@date" />
            </xsl:call-template>
          </span>
        </span><xsl:value-of select="$newline" />
        <p class="changelog-release-para">Changes:</p><xsl:value-of select="$newline" />
        <xsl:for-each select="cl:change">
          <xsl:apply-templates select="." />
        </xsl:for-each>
      </div><xsl:value-of select="$newline" />
    </dd><xsl:value-of select="$newline" />
  </xsl:template>

</xsl:stylesheet>
