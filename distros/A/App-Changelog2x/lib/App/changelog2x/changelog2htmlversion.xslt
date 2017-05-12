<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: changelog2htmlversion.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet transforms ChangeLogML content into a XHTML
    fragment whose top-level element is a "span". The content of the
    element is the version-string (from the @version attribute) of the
    newest release, as sorted by the @date attributes.

    The template recognizes only the following input parameter:

    class
      Allows the user to specify a CSS class for the span. If not given,
      the class defaults to "changelog-version-span".
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
    The "class" parameter controls the CSS class assigned to the outer-most
    containing div element. The rest of the content uses the same set of
    classes as the other XHTML-oriented styles do. But specifying this should
    allow the user to set up their own complete hierarchy, using the right
    selectors.
  -->
  <xsl:param name="class" select="'changelog-version-span'" />

  <xsl:template match="/">
    <xsl:call-template name="insert-comment">
      <xsl:with-param name="id"><![CDATA[$Id: changelog2htmlversion.xslt 8 2009-01-19 06:46:50Z rjray $]]></xsl:with-param>
    </xsl:call-template>
    <xsl:for-each select="cl:changelog//cl:release">
      <xsl:sort select="@date" data-type="text" order="descending" />
      <xsl:if test="position() = 1">
        <span class="{$class}"><xsl:value-of select="./@version" /></span>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
