<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: changelog2htmlnewest.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet transforms ChangeLogML content into a XHTML
    fragment whose top-level element is a "div". The container is given
    an ID attribute of "changelog-container", and a class that either
    follows in the pattern of all the changelog-derived XHTML elements or
    is provided by the user. The content of the top-level div is just one
    release-div, that of the newest release as sorted by the @date
    attributes.

    The template recognizes only the following input parameter:

    class
      Allows the user to specify the CSS class for the top-level div. If
      this is not passed, then the default class is "changelog-container-div".
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
  <xsl:param name="class" select="'changelog-container-div'" />

  <xsl:template match="/">
    <xsl:call-template name="insert-comment">
      <xsl:with-param name="id"><![CDATA[$Id: changelog2htmlnewest.xslt 8 2009-01-19 06:46:50Z rjray $]]></xsl:with-param>
    </xsl:call-template>
    <div id="changelog-container" class="{$class}"><xsl:value-of select="$newline" />
      <xsl:for-each select="cl:changelog//cl:release">
        <xsl:sort select="@date" data-type="text" order="descending" />
        <xsl:if test="position() = 1">
          <xsl:apply-templates select="." />
        </xsl:if>
      </xsl:for-each>
    </div>
  </xsl:template>

</xsl:stylesheet>
