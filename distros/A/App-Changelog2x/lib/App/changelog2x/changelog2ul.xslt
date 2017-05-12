<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: changelog2ul.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet transforms ChangeLogML content into a XHTML
    fragment whose top-level element is a "ul". The container is given
    an ID attribute of "changelog-container", and a class that follows in
    the pattern of all the changelog-derived XHTML elements. Each of the
    per-release "div" blocks are contained with "li" elements.

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
    This snippet contains most of the core XHTML-generation templates. It will
    also be used by the stylesheets that generate only div's, ul's, etc.
    Some will use xsl:import rather than xsl:include so as to override some
    functionality, but for this stylesheet everything is needed as-is.
  -->
  <xsl:include href="common-xhtml.xslt" />

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
    For this stylesheet, the desired output is a ul container that itself
    contains all the release-divs (possibly trimmed down by the 'versions'
    parameter) as the li's. None of the rest of the XHTML boilerplate is
    needed.
  -->
  <xsl:template match="/">
    <xsl:call-template name="insert-comment">
      <xsl:with-param name="id"><![CDATA[$Id: changelog2ul.xslt 8 2009-01-19 06:46:50Z rjray $]]></xsl:with-param>
    </xsl:call-template>
    <ul xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"
        id="changelog-container" class="changelog-container-ul"><xsl:value-of select="$newline" />
      <xsl:for-each select="cl:changelog//cl:release">
        <xsl:sort select="@date" data-type="text" order="{$order}" />
        <xsl:choose>
          <xsl:when test="$versions = 'first'">
            <xsl:if test="position() = 1">
              <li class="changelog-container-ul-li"><xsl:value-of select="$newline" />
                <xsl:apply-templates select="." />
              </li><xsl:value-of select="$newline" />
            </xsl:if>
          </xsl:when>
          <!-- Seems like an odd test, but really just avoids the default
               case of 'all' -->
          <xsl:when test="$versions != '' and $versions != 'all'">
            <xsl:if test="contains(concat(',', $versions, ','), concat(',', @version, ','))">
              <li class="changelog-container-ul-li"><xsl:value-of select="$newline" />
                <xsl:apply-templates select="." />
              </li><xsl:value-of select="$newline" />
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <li class="changelog-container-ul-li"><xsl:value-of select="$newline" />
              <xsl:apply-templates select="." />
            </li><xsl:value-of select="$newline" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </ul>
  </xsl:template>

</xsl:stylesheet>
