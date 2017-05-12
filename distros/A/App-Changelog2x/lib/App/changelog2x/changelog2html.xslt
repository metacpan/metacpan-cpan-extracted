<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: changelog2html.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet transforms ChangeLogML content into a complete XHTML
    document. A comprehensive set of CSS classes are assigned to all tags
    that are generated. See the documentation for details on the names of
    the classes and their hierarchy.

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
    notoc
      If present and a non-zero value, then the generation of the "table of
      contents"-style links at the top of the document, and the back-links
      on each release-div, are suppressed.
    css
      If passed, it is used verbatim as the href-locator for a "link" tag
      in the head-section of the document, assumed to point to a CSS
      stylesheet.
    color
      If passed, it is also used verbatim as a CSS stylesheet URL. This is
      handled identically to "css", previously, and differs only in that it
      occurs *after* the previous one, allowing its contents to take priority
      per the CSS cascade model.
    javascript
      Like the previous, this is treated verbatim as a URL. However, it is
      presumed to be a Javascript file, and is used in a "script" tag.
    headcontent
      An open-ended parameter, if it is passed and is non-null the contents
      are inserted into the head-section of the document at the very end,
      after any content generated to accommodate the "css", "color" or
      "javascript" parameters. No tests or checks are done to the content
      to ensure that the document continues to be valid XHTML. This is
      added at the end, so that if it contains additional CSS stylesheets
      or Javascript content, they occur after the previous parameters'
      content (for sake of the cascade model, for example).
    bodycontent
      Another open-ended container like the previous parameter. This one
      goes in the body-section, and goes as the first content, before any
      of the stylesheet-generated content. This allows the user to insert
      additional Javascript, etc. if needed.
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
  <xsl:output method="html" indent="no"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
              doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" />

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
    The "notoc" parameter tells the stylesheet to suppress the generation of
    table-of-contents-style links at the top of the document and "[top]"
    return-links on each version-line.
  -->
  <xsl:param name="notoc" select="''" />

  <!--
    If the "css" parameter is provided, it is taken as the URL to a CSS
    stylesheet that provides stylings for the classes used in the generated
    XHTML. This is included as a <link> element in the <head> section of the
    document, and is only generated when the "output" parameter is set to
    "full" (as links are only valid in head-sections, and none of the other
    output options includes a head-section).
  -->
  <xsl:param name="css" />

  <!--
    Similar to the above, this is taken as a CSS URL that refers to a color
    scheme.
  -->
  <xsl:param name="color" />

  <!--
    Likewise, if the "javascript" parameter is provided, it is taken as the URL
    of a Javascript resource to be included in a <script> element. Same
    conditions/restrictions as "css", above.
  -->
  <xsl:param name="javascript" />

  <!--
    These two parameters allow for generic large-scale content additions in
    the <head> and <body> blocks. No testing or checking is done on them.
  -->
  <xsl:param name="headcontent" />
  <xsl:param name="bodycontent" />

  <!--
    This template is the start of it all, matching at root and handling the
    set-up of the overall XHTML document. It picks over the top-most elements
    of the ChangeLog being processed to create title, abstract, etc. Then it
    passes off the child-elements to the templates that were pulled in via
    the inclusion of common-xhtml.xslt.
  -->
  <xsl:template match="/">
    <xsl:variable name="suppress_toc">
      <xsl:choose>
        <xsl:when test="($notoc = '') and ($versions = 'all') and (count(/cl:changelog//cl:release) > 1)">
          <xsl:value-of select="''" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="1" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"><xsl:value-of select="$newline" />
      <xsl:call-template name="insert-comment">
        <xsl:with-param name="id"><![CDATA[$Id: changelog2html.xslt 8 2009-01-19 06:46:50Z rjray $]]></xsl:with-param>
      </xsl:call-template>
      <xsl:value-of select="$newline" />
      <head><xsl:value-of select="$newline" />
        <title><xsl:value-of select="$title" /></title><xsl:value-of select="$newline" />
        <xsl:if test="$css">
          <link rel="stylesheet" type="text/css">
            <xsl:attribute name="href">
              <xsl:value-of select="$css" />
            </xsl:attribute>
          </link><xsl:value-of select="$newline" />
        </xsl:if>
        <xsl:if test="$color">
          <link rel="stylesheet" type="text/css">
            <xsl:attribute name="href">
              <xsl:value-of select="$color" />
            </xsl:attribute>
          </link><xsl:value-of select="$newline" />
        </xsl:if>
        <xsl:if test="$javascript">
          <script type="text/javascript">
            <xsl:attribute name="href">
              <xsl:value-of select="$javascript" />
            </xsl:attribute>
          </script><xsl:value-of select="$newline" />
        </xsl:if>
        <xsl:if test="$headcontent">
          <xsl:value-of select="$headcontent" /><xsl:value-of select="$newline" />
        </xsl:if>
      </head><xsl:value-of select="$newline" />
      <body class="changelog"><xsl:value-of select="$newline" />
        <xsl:if test="$bodycontent">
          <xsl:value-of select="$bodycontent" /><xsl:value-of select="$newline" />
        </xsl:if>
        <h1 id="top" class="changelog-title"><xsl:value-of select="$title" /></h1><xsl:value-of select="$newline" />
        <xsl:if test="cl:changelog/cl:description">
          <p class="changelog-abstract"><xsl:apply-templates select="cl:changelog/cl:description" /></p><xsl:value-of select="$newline" />
        </xsl:if>
        <!--
          Create a "table of contents" set of links to the releases, unless
          suppressed by the user.
        -->
        <xsl:if test="$suppress_toc = ''">
          <div class="changelog-toc-div"><xsl:value-of select="$newline" />
            <xsl:for-each select="cl:changelog//cl:release">
              <xsl:sort select="@date" data-type="text" order="ascending" />
              <xsl:apply-templates select="." mode="toc" />
            </xsl:for-each>
          </div><xsl:value-of select="$newline" />
        </xsl:if>
        <hr class="changelog-divider" /><xsl:value-of select="$newline" />
        <div id="changelog-container-div" class="changelog-container-div"><xsl:value-of select="$newline" />
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
                <xsl:apply-templates select=".">
                  <xsl:with-param name="no_link_to_top" select="$suppress_toc" />
                  <xsl:with-param name="position" select="position()" />
                </xsl:apply-templates>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </div><xsl:value-of select="$newline" />
        <hr class="changelog-divider" /><xsl:value-of select="$newline" />
      </body><xsl:value-of select="$newline" />
    </html>
  </xsl:template>

  <xsl:template match="cl:release" mode="toc">
    <xsl:variable name="version" select="translate(@version, '.', '_')" />
    <xsl:variable name="div_id" select="concat('release_', $version, '_div')" />
    <xsl:variable name="title">
      <xsl:choose>
        <xsl:when test="function-available('cl:format-date')">
          <xsl:value-of select="concat('Jump to version ', @version, ', released ', cl:format-date(@date))" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('Jump to version ', @version)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <a class="changelog-toc-link" title="{$title}" href="#{$div_id}"><xsl:value-of select="@version" /></a><xsl:value-of select="$newline" />
  </xsl:template>

</xsl:stylesheet>
