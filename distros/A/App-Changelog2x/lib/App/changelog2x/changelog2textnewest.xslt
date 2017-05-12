<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: changelog2textnewest.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet transforms ChangeLogML content into a plain-text
    fragment whose content is the newest release, as sorted by the @date
    attributes. None of the extra content for the head or tail-end of the
    full plain-text changelog is generated, only one block for the given
    release.

    The template utilizes no input parameters.
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
    This template starts the process, at the root of the ChangeLogML document.
    For this style, we only want the newest of the releases, with none of the
    boilerplate (not even credits).
  -->
  <xsl:template match="/">
    <xsl:for-each select="cl:changelog//cl:release">
      <xsl:sort select="@date" data-type="text" order="descending" />
      <xsl:if test="position() = 1">
        <xsl:apply-templates select="." />
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
