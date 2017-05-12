<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: common-xhtml.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet contains all the operations/templates that are
    common to the XHTML stylesheets.
-->
<xsl:stylesheet version="1.0"
                xmlns:cl="http://www.blackperl.com/2009/01/ChangeLogML"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml">

  <!--
    The source-control identifying string for this component, used in some
    credits-comments.
  -->
  <xsl:variable name="common-xhtml-id">
    <xsl:text><![CDATA[$Id: common-xhtml.xslt 8 2009-01-19 06:46:50Z rjray $]]></xsl:text>
  </xsl:variable>

  <!--
    This template creates a simple XML/XHTML comment block that contains the
    current date/time stamp from the global parameter "$now", the string of
    app/library information from the global "$credits", and whatever the caller
    passed in the parameter "id" (usually the "Id" keyword from the version-
    control system, expanded for the calling file).
  -->
  <xsl:template name="insert-comment">
    <xsl:param name="id" select="''" />
    <xsl:param name="indent" select="'    '" />
    <xsl:comment>
      <xsl:value-of select="$newline" />
      <xsl:value-of select="$indent" />
      <xsl:text>Generated on </xsl:text>
      <xsl:value-of select="$now" />
      <xsl:value-of select="$newline" />
      <xsl:value-of select="$indent" />
      <xsl:text>Using </xsl:text>
      <xsl:value-of select="$credits" />
      <xsl:value-of select="$newline" />
      <xsl:value-of select="$indent" />
      <xsl:text>XSLT Sources:</xsl:text>
      <xsl:value-of select="$newline" />
      <xsl:if test="$id != ''">
        <xsl:value-of select="$indent" />
        <xsl:value-of select="$indent" />
        <xsl:value-of select="$id" />
        <xsl:value-of select="$newline" />
      </xsl:if>
      <xsl:value-of select="$indent" />
      <xsl:value-of select="$indent" />
      <xsl:value-of select="$common-xhtml-id" />
      <xsl:value-of select="$newline" />
      <xsl:value-of select="$indent" />
      <xsl:value-of select="$indent" />
      <xsl:value-of select="$common-id" />
      <xsl:value-of select="$newline" />
    </xsl:comment>
  </xsl:template>

  <!--
    This template handles the div-block for a single release. It uses the value
    of the @version attribute to create a unique ID attribute for the generated
    div, as well as an anchor for the a-tag that wraps the h2.
  -->
  <xsl:template name="release-div" match="cl:release">
    <xsl:param name="no_link_to_top" select="1" />
    <xsl:param name="position" select="0" />
    <xsl:variable name="version" select="translate(@version, '.', '_')" />
    <xsl:variable name="div_id" select="concat('release_', $version, '_div')" />
    <xsl:variable name="anchor_id" select="concat('release_', $version)" />
    <xsl:variable name="subproject">
      <xsl:if test="local-name(..) = 'subproject'">
        <xsl:value-of select="../@name" />
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="path-prefix">
      <xsl:if test="local-name(..) = 'subproject'">
        <xsl:value-of select="concat(../@path, '/')" />
      </xsl:if>
    </xsl:variable>
    <div class="changelog-release-div" name="{$anchor_id}" id="{$div_id}"><xsl:value-of select="$newline" />
      <xsl:if test="$subproject != ''">
        <span class="changelog-subproject-heading">
          <xsl:text>Subproject: </xsl:text><xsl:value-of select="$subproject" />
        </span>
        <br /><xsl:value-of select="$newline" />
      </xsl:if>
      <span class="changelog-release-heading">
        <xsl:text>Version: </xsl:text><xsl:value-of select="@version" />
      </span>
      <xsl:if test="($no_link_to_top = '') and ($position != 1)">
        <xsl:text> </xsl:text>
        <a class="changelog-toc-link" href="#top">[top]</a>
      </xsl:if>
      <br />
      <xsl:value-of select="$newline" />
      <span class="changelog-release-date">
        <xsl:text>Released: </xsl:text>
        <span class="changelog-date">
          <xsl:call-template name="format-date">
            <xsl:with-param name="date" select="@date" />
          </xsl:call-template>
        </span>
      </span><xsl:value-of select="$newline" />
      <xsl:if test="cl:description">
        <p class="changelog-release-description"><xsl:value-of select="$newline" />
          <xsl:apply-templates select="cl:description" /><xsl:value-of select="$newline" />
        </p><xsl:value-of select="$newline" />
      </xsl:if>
      <p class="changelog-release-para">Changes:</p><xsl:value-of select="$newline" />
      <div class="changelog-release-changes-container"><xsl:value-of select="$newline" />
        <xsl:for-each select="cl:change">
          <xsl:apply-templates select=".">
            <xsl:with-param name="path-prefix" select="$path-prefix" />
          </xsl:apply-templates>
        </xsl:for-each>
      </div><xsl:value-of select="$newline" />
    </div><xsl:value-of select="$newline" />
  </xsl:template>

  <!--
    This template formats a single change within a release-div-block. It has
    to handle the test of a single file-tag vs. a fileset container, display
    any revision/version info that's separate from the VCS info, and of
    course the doc-block as well.
  -->
  <xsl:template name="change-div" match="cl:change">
    <xsl:param name="path-prefix" select="''" />
    <div class="changelog-release-change"><xsl:value-of select="$newline" />
      <xsl:if test="cl:fileset/@revision">
        <span class="changelog-transaction-revision">Transaction revision: <xsl:value-of select="cl:fileset/@revision" /></span><xsl:value-of select="$newline" />
      </xsl:if>
      <ul class="changelog-release-change-ul"><xsl:value-of select="$newline" />
        <xsl:choose>
          <xsl:when test="cl:fileset/cl:file">
            <xsl:for-each select="cl:fileset/cl:file">
              <xsl:sort select="@path" data-type="text" />
              <xsl:apply-templates select=".">
                <xsl:with-param name="path-prefix" select="$path-prefix" />
              </xsl:apply-templates>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="cl:file">
              <xsl:with-param name="path-prefix" select="$path-prefix" />
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </ul><xsl:value-of select="$newline" />
      <p class="changelog-release-change-para"><xsl:value-of select="$newline" />
        <xsl:apply-templates select="cl:description" />
      </p><xsl:value-of select="$newline" />
    </div><xsl:value-of select="$newline" />
  </xsl:template>

  <!--
    This template is for an individual file within a change-block. The main
    logic here is determining from the @action attribute (if present) what
    additional text to append to the line (whether the file was added, deleted,
    moved, etc.).
  -->
  <xsl:template name="change-file" match="cl:file">
    <xsl:param name="path-prefix" select="''" />
    <li class="changelog-release-change-li"><xsl:value-of select="$newline" />
      <tt class="changelog-filename"><xsl:value-of select="concat($path-prefix, @path)" /></tt>
      <xsl:if test="@revision">
        <xsl:text>, </xsl:text><span class="changelog-file-revision">revision <xsl:value-of select="@revision" /></span><xsl:value-of select="$newline" />
      </xsl:if>
      <xsl:if test="@action">
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="@action = 'ADD'">
            <span class="changelog-release-file-action">(added)</span>
          </xsl:when>
          <xsl:when test="@action = 'DELETE'">
            <span class="changelog-release-file-action">(deleted)</span>
          </xsl:when>
          <xsl:when test="@action = 'RESTORE'">
            <span class="changelog-release-file-action">(restored)</span>
          </xsl:when>
          <xsl:when test="@action = 'MOVE'">
            <span class="changelog-release-file-action">(moved)</span>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
      <xsl:value-of select="$newline" />
    </li><xsl:value-of select="$newline" />
  </xsl:template>

  <!--
    This template causes tags in the xhtml: namespace to get passed through to
    the output essentially unchanged. The only change is that a "class"
    attribute is added, to allow for CSS styling in the same stylesheet as
    the end-user is creating for the rest of the ChangeLog. If the tag already
    has a "class" attribute, the attribute is copied over intact and the new
    style is added at the end.
  -->
  <xsl:template name="xhtml-passthrough" match="xhtml:*">
    <xsl:element name="{local-name()}">
      <!-- Pass through any attr EXCEPT 'class' unchanged -->
      <xsl:for-each select="@*[not(local-name() = 'class')]">
        <xsl:attribute name="{local-name()}">
          <xsl:value-of select="." />
        </xsl:attribute>
      </xsl:for-each>
      <!-- If the 'class' attr exists, append to it. Else, add it. -->
      <xsl:choose>
        <xsl:when test="@class">
          <xsl:attribute name="class">
            <xsl:value-of select="./@class" /><xsl:text> changelog-html-</xsl:text><xsl:value-of select="local-name()" />
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="class">
            <xsl:text>changelog-html-</xsl:text><xsl:value-of select="local-name()" />
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
