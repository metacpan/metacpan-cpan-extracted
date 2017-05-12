<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: svnxml2changes.xslt 14 2009-01-23 01:41:18Z rjray $

    This XSLT stylesheet transforms the XML-style output from Subversion's
    "log" command into ChangeLogML "change" blocks. It uses some
    text-formatting recipes from the XSLT Cookbook published by O'Reilly &
    Associates.

    Suggested usage:

        svn log -v -r RANGE - -xml | xsltproc svnxml2changes.xslt -
                            ^^^ delete this space, double-dashes cannot
                                occur in XML comments

    The "-v" option to "svn log" is important, as it causes file information
    to be included in the log output.
-->
<xsl:stylesheet version="1.0"
                xmlns:cl="http://www.blackperl.com/2009/01/ChangeLogML"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://www.ora.com/XSLTCookbook/namespaces/strings"
                xmlns:text="http://www.ora.com/XSLTCookbook/namespaces/text">

  <xsl:strip-space elements="*" />
  <xsl:output method="xml" indent="no" omit-xml-declaration="yes" />
  <!-- Platform-agnostic newline character -->
  <xsl:variable name="newline">
<xsl:text>
</xsl:text>
  </xsl:variable>

  <!-- If the user provides a value for this, remove it from any paths -->
  <xsl:param name="pathremove" select="''" />

  <xsl:template match="/">
    <xsl:apply-templates select="/log/logentry" />
  </xsl:template>

  <!-- "logentry" blocks in the SVN stream correspond to "change" blocks -->
  <xsl:template	match="logentry">
    <xsl:element name="change">
      <xsl:attribute name="date">
        <xsl:value-of select="date"	/>
      </xsl:attribute>
      <xsl:if test="author">
        <xsl:attribute name="author">
          <xsl:value-of select="author" />
        </xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="count(paths/path) = 1">
          <!-- If there is just one path elem, emit a single "file" block -->
          <xsl:value-of select="$newline" />
          <xsl:apply-templates select="paths/path">
            <xsl:with-param name="revision" select="@revision" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <!--  Otherwise, start a "fileset" block for the set of paths -->
          <xsl:value-of select="$newline" />
          <xsl:element name="fileset">
            <xsl:attribute name="revision">
              <xsl:value-of select="@revision" />
            </xsl:attribute>
            <xsl:value-of select="$newline" />
            <xsl:for-each select="paths/path">
              <xsl:sort	select="text()" data-type="text" />
              <xsl:apply-templates select="." />
            </xsl:for-each>
          </xsl:element>
          <xsl:value-of select="$newline" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:element name="description">
        <xsl:value-of select="$newline" />
        <!--
          Use the text:wrap recipes from XSLT Cookbook to pretty-print the
          log message.
        -->
        <xsl:call-template name="text:wrap">
          <xsl:with-param name="input" select="normalize-space(msg)" />
          <xsl:with-param name="width" select="70" />
        </xsl:call-template>
      </xsl:element>
      <xsl:value-of select="$newline" />
    </xsl:element>
    <xsl:value-of select="$newline" />
  </xsl:template>

  <!-- Handle one "path" element, creating a "file" element in the output -->
  <xsl:template match="path">
    <xsl:param name="revision" />
    <xsl:element name="file">
      <xsl:attribute name="path">
        <xsl:choose>
          <xsl:when test="($pathremove != '') and starts-with(., $pathremove)">
            <xsl:value-of select="substring(., string-length($pathremove)+1)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="." />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="@action != 'M'">
        <!--
          If the @action attribute is *not* M, translate it. If it *is* M, that
          corresponds to the default value of the action attribute on "file"
          and thus isn't needed.
        -->
        <xsl:attribute name="action">
          <xsl:choose>
            <xsl:when test="@action = 'A'">
              <xsl:text>ADD</xsl:text>
            </xsl:when>
            <xsl:when test="@action = 'D'">
              <xsl:text>DELETE</xsl:text>
            </xsl:when>
            <xsl:when test="@action = 'R'">
              <xsl:text>RESTORE</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$revision != ''">
        <!--
          If a revision value was passed in, add itas an attribute. If it
          wasn't passed in, it was handled at the "fileset" level.
        -->
        <xsl:attribute name="revision">
          <xsl:value-of select="$revision" />
        </xsl:attribute>
      </xsl:if>
    </xsl:element>
    <xsl:value-of select="$newline" />
  </xsl:template>

  <!--
      The following four template declarations are taken almost verbatim from
      O'Reilly & Associates' _XSLT Cookbook_. I've made some changes to the
      text:wrap template to make the indention string caller-selectable.
  -->

  <!-- XSLT Cookbook, recipe 5.6 -->
  <xsl:template match="node()|@*" mode="text:wrap" name="text:wrap">
    <xsl:param name="input" select="normalize-space()" />
    <xsl:param name="width" select="70" />
    <xsl:param name="align-width" select="$width" />
    <xsl:param name="align" select="'left'"/>
    <xsl:param name="indent" select="0" />
    <xsl:param name="indent-with" select="' '" />

    <xsl:if test="$input">
      <xsl:variable name="line">
        <xsl:choose>
          <xsl:when test="string-length($input) > $width">
            <xsl:variable name="candidate-line"
                          select="substring($input,1,$width)" />
            <xsl:choose>
              <xsl:when test="contains($candidate-line, ' ')">
                <xsl:call-template name="str:substring-before-last">
                  <xsl:with-param name="input" select="$candidate-line"/>
                  <xsl:with-param name="substr" select="' '"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$candidate-line"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$input"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="$line">
        <xsl:call-template name="str:dup">
          <xsl:with-param name="input" select="$indent-with" />
          <xsl:with-param name="count" select="$indent" />
        </xsl:call-template>
        <xsl:call-template name="text:justify">
          <xsl:with-param name="value" select="$line"/>
          <xsl:with-param name="width" select="$align-width"/>
          <xsl:with-param name="align" select="$align"/>
        </xsl:call-template>
        <xsl:value-of select="$newline" />
      </xsl:if>

      <xsl:call-template name="text:wrap">
        <xsl:with-param name="input"
                        select="substring($input, string-length($line) + 2)" />
        <xsl:with-param name="width" select="$width" />
        <xsl:with-param name="align-width" select="$align-width" />
        <xsl:with-param name="align" select="$align" />
        <xsl:with-param name="indent" select="$indent" />
        <xsl:with-param name="indent-with" select="$indent-with" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- XSLT Cookbook, recipe 5.3 -->
  <xsl:template name="text:justify">
    <xsl:param name="value" />
    <xsl:param name="width" select="10" />
    <xsl:param name="align" select="'left'" />
    <xsl:param name="pad-with" select="' '" />
    <!-- Truncate if too long -->
    <xsl:variable name="output" select="substring($value,1,$width)" />
    <xsl:choose>
      <xsl:when test="$align = 'left'">
        <xsl:value-of select="$output"/>
        <xsl:call-template name="str:dup">
          <xsl:with-param name="input" select="$pad-with"/>
          <xsl:with-param name="count"
                          select="$width - string-length($output)" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$align = 'right'">
        <xsl:call-template name="str:dup">
          <xsl:with-param name="input" select="$pad-with" />
          <xsl:with-param name="count"
                          select="$width - string-length($output)" />
        </xsl:call-template>
        <xsl:value-of select="$output" />
      </xsl:when>
      <xsl:when test="$align = 'center'">
        <xsl:call-template name="str:dup">
          <xsl:with-param name="input" select="$pad-with" />
          <xsl:with-param name="count"
                          select=
                          "floor(($width - string-length($output)) div 2)" />
        </xsl:call-template>
        <xsl:value-of select="$output" />
        <xsl:call-template name="str:dup">
          <xsl:with-param name="input" select="$pad-with" />
          <xsl:with-param name="count"
                          select=
                          "ceiling(($width - string-length($output)) div 2)" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>INVALID ALIGN</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- XSLT Cookbook, recipe 1.4 -->
  <xsl:template name="str:substring-before-last">
    <xsl:param name="input" />
    <xsl:param name="substr" />
    <xsl:if test="$substr and contains($input, $substr)">
      <xsl:variable name="temp" select="substring-after($input, $substr)" />
      <xsl:value-of select="substring-before($input, $substr)" />
      <xsl:if test="contains($temp, $substr)">
        <xsl:value-of select="$substr" />
        <xsl:call-template name="str:substring-before-last">
          <xsl:with-param name="input" select="$temp" />
          <xsl:with-param name="substr" select="$substr" />
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template name="str:substring-after-last">
    <xsl:param name="input" />
    <xsl:param name="substr" />
    <!-- Extract the string which comes after the first occurence -->
    <xsl:variable name="temp" select="substring-after($input,$substr)" />
    <xsl:choose>
      <xsl:when test="$substr and contains($temp,$substr)">
        <xsl:call-template name="str:substring-after-last">
          <xsl:with-param name="input" select="$temp" />
          <xsl:with-param name="substr" select="$substr" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$temp" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- XSLT Cookbook, recipe 1.5 -->
  <xsl:template name="str:dup">
    <xsl:param name="input" />
    <xsl:param name="count" select="1" />
    <xsl:choose>
      <xsl:when test="not($count) or not($input)" />
      <xsl:when test="$count = 1">
        <xsl:value-of select="$input" />
      </xsl:when>
      <xsl:otherwise>
        <!-- If $count is odd append an extra copy of input -->
        <xsl:if test="$count mod 2">
          <xsl:value-of select="$input"/>
        </xsl:if>
        <!-- Recursively apply template after doubling input and halving
             count -->
        <xsl:call-template name="str:dup">
          <xsl:with-param name="input" select="concat($input,$input)" />
          <xsl:with-param name="count" select="floor($count div 2)" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
