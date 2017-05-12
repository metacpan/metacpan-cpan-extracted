<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: changelog2text.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet transforms ChangeLogML content into a plain-text
    document that closely follows the defacto-standard format for
    Changelog files in existing open-source projects.

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
                xmlns:str="http://www.ora.com/XSLTCookbook/namespaces/strings"
                xmlns:text="http://www.ora.com/XSLTCookbook/namespaces/text">

  <!--
    This snippet contains most of the core text-generation templates. It will
    also be used by the stylesheets that generate only partial content. Some
    may use xsl:import rather than xsl:include so as to override some
    functionality, but for this stylesheet everything is needed as-is.
  -->
  <xsl:include href="common-text.xslt" />

  <!--
    This snippet-file contains common variable declarations (date at the moment,
    the "credits" string to identify the processor) and non-content templates
    such as the date-formatter (which only returns a string, no XHTML or
    plain-text-specific material).
  -->
  <xsl:include href="common.xslt" />

  <xsl:strip-space elements="*" />
  <xsl:output method="text" indent="no"/>

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

  <!--
    This template starts the process, at the root of the ChangeLogML document.
    Emit the boilerplate info (date of processing, credits, etc.) and the
    project name and abstract. Then the remainder is handled through other
    templates.
  -->
  <xsl:template match="/">
    <xsl:call-template name="text:wrap">
      <xsl:with-param name="input" select="$title" />
      <xsl:with-param name="width" select="72" />
      <xsl:with-param name="indent" select="4" />
      <xsl:with-param name="align" select="'center'" />
    </xsl:call-template>
    <xsl:value-of select="$newline" />
    <xsl:apply-templates select="cl:changelog/cl:description" mode="text:wrap">
      <xsl:with-param name="width" select="48" />
      <xsl:with-param name="indent" select="2" />
      <xsl:with-param name="indent-with" select="$tab" />
    </xsl:apply-templates>
    <xsl:value-of select="$newline" />
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
            <xsl:if test="position() != 1">
              <xsl:value-of select="$newline" />
            </xsl:if>
            <xsl:apply-templates select="." />
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="position() != 1">
            <xsl:value-of select="$newline" />
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:value-of select="$newline" />
    <xsl:text># Generated on </xsl:text>
    <xsl:value-of select="$now" />
    <xsl:value-of select="$newline" />
    <xsl:call-template name="text:wrap">
      <xsl:with-param name="input" select="concat('Using ', $credits)" />
      <xsl:with-param name="width" select="77" />
      <xsl:with-param name="indent" select="1" />
      <xsl:with-param name="indent-with" select="'# '" />
    </xsl:call-template>
    <xsl:text># XSLT sources:</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:text>#     $Id: changelog2text.xslt 8 2009-01-19 06:46:50Z rjray $</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:text>#     </xsl:text>
    <xsl:value-of select="$common-text-id" />
    <xsl:value-of select="$newline" />
    <xsl:text>#     </xsl:text>
    <xsl:value-of select="$common-id" />
    <xsl:value-of select="$newline" />
  </xsl:template>

</xsl:stylesheet>
