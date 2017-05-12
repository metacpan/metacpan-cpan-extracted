<?xml version="1.0" encoding="UTF-8"?>
<!--
    :tabSize=2:indentSize=2:wrap=hard:
    $Id: common-text.xslt 8 2009-01-19 06:46:50Z rjray $

    This XSLT stylesheet contains the operations/templates that are common
    to all of the text-oriented stylesheets. This includes several recipes
    taken from the ORA volume, "XSLT Cookbook".
-->
<xsl:stylesheet version="1.0"
                xmlns:cl="http://www.blackperl.com/2009/01/ChangeLogML"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://www.ora.com/XSLTCookbook/namespaces/strings"
                xmlns:text="http://www.ora.com/XSLTCookbook/namespaces/text">

  <!--
    The source-control identifying string for this component, used in some
    credits-comments.
  -->
  <xsl:variable name="common-text-id">
    <xsl:text><![CDATA[$Id: common-text.xslt 8 2009-01-19 06:46:50Z rjray $]]></xsl:text>
  </xsl:variable>

  <xsl:template name="release" match="cl:release">
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
    <xsl:value-of select="@version" />
    <xsl:value-of select="$tab" />
    <xsl:call-template name="format-date">
      <xsl:with-param name="date" select="@date" />
    </xsl:call-template>
    <xsl:value-of select="$newline" />
    <xsl:if test="$subproject != ''">
      <xsl:value-of select="$tab"	/>
      <xsl:text>Subproject: </xsl:text>
      <xsl:value-of select="$subproject" />
      <xsl:value-of select="$newline" />
    </xsl:if>
    <xsl:for-each select="cl:change">
      <xsl:apply-templates select=".">
        <xsl:with-param name="path-prefix" select="$path-prefix" />
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="change" match="cl:change">
    <xsl:param name="path-prefix" select="''" />
    <xsl:value-of select="$newline" />
    <xsl:if test="cl:fileset/@revision">
      <xsl:value-of select="$tab" />
      <xsl:text>Transaction revision: </xsl:text>
      <xsl:value-of select="cl:fileset/@revision" />
      <xsl:value-of select="$newline" />
    </xsl:if>
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
    <xsl:apply-templates select="cl:description" mode="text:wrap">
      <xsl:with-param name="width" select="64" />
      <xsl:with-param name="indent" select="1" />
      <xsl:with-param name="indent-with" select="$tab" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template name="change-file" match="cl:file">
    <xsl:param name="path-prefix" select="''" />
    <xsl:value-of select="$tab" />
    <xsl:text>* </xsl:text>
    <xsl:value-of select="concat($path-prefix, @path)" />
    <xsl:if test="@revision">
      <xsl:text>, revision </xsl:text>
      <xsl:value-of select="@revision" />
    </xsl:if>
    <xsl:if test="@action">
      <xsl:text> </xsl:text>
      <xsl:choose>
        <xsl:when test="@action = 'ADD'">
          <xsl:text>(added)</xsl:text>
        </xsl:when>
        <xsl:when test="@action = 'DELETE'">
          <xsl:text>(deleted)</xsl:text>
        </xsl:when>
        <xsl:when test="@action = 'RESTORE'">
          <xsl:text>(restored)</xsl:text>
        </xsl:when>
        <xsl:when test="@action = 'MOVE'">
          <xsl:text>(moved)</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
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
