<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<!--
This stylesheet is not meant to be used in isolation. Either use it as part
of a pipeline (in which case uncomment the below default template for
'*|@*'), or <xsl:import> or <xsl:include> it into your own stylesheet.
-->

<!-- Commented out for use in <xsl:import> rather than a pipeline -->
<!--
<xsl:template match="*|@*">
  <xsl:copy>
   <xsl:apply-templates select="@*"/>
   <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>
-->

<xsl:template match="formerrors">
    <xsl:apply-templates select="..//error"/>
</xsl:template>

<xsl:template match="error">
  <span class="form_error"><xsl:value-of select="."/></span>
</xsl:template>

<xsl:template match="form">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates/>
    </xsl:copy>
</xsl:template>

<xsl:template match="textfield">
    <input 
        type="text"
        name="{@name|name}{@index|index}" 
        value="{@value|value}" 
        size="{@width|width}" 
        maxlength="{@maxlength|maxlength}">
        <xsl:if test="@disabled or disabled"><xsl:attribute
            name="disabled">disabled</xsl:attribute></xsl:if>
        <xsl:if test="@onchange or onchange">
          <xsl:attribute name="onchange"><xsl:value-of select="@onchange|onchange"/></xsl:attribute>
        </xsl:if>
    </input>
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="password">
    <input 
        type="password"
        name="{@name|name}{@index|index}" 
        value="{@value|value}" 
        size="{@width|width}" 
        maxlength="{@maxlength|maxlength}">
        <xsl:if test="@disabled or disabled"><xsl:attribute
            name="disabled">disabled</xsl:attribute></xsl:if>
        <xsl:if test="@onchange or onchange">
          <xsl:attribute name="onchange"><xsl:value-of select="@onchange|onchange"/></xsl:attribute>
        </xsl:if>
    </input>
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="checkbox">
    <input
        type="checkbox"
        name="{@name|name}{@index|index}"
        value="{@value|value}">
      <xsl:if test="@checked = 'checked' or checked = 'checked'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
        <xsl:if test="@disabled or disabled"><xsl:attribute
            name="disabled">disabled</xsl:attribute></xsl:if>
        <xsl:if test="@onclick or onclick">
          <xsl:attribute name="onclick"><xsl:value-of select="@onclick|onclick"/></xsl:attribute>
        </xsl:if>
    </input>
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="submit_button">
    <input
        type="submit"
        name="{@name|name}{@index|index}"
        value="{@value|value}">
        <xsl:if test="@disabled or disabled"><xsl:attribute
            name="disabled">disabled</xsl:attribute></xsl:if>
        <xsl:if test="@onclick or onclick">
          <xsl:attribute name="onclick"><xsl:value-of select="@onclick|onclick"/></xsl:attribute>
        </xsl:if>
    </input>
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="hidden">
    <input
        type="hidden"
        name="{@name|name}{@index|index}"
        value="{@value|value}" />
</xsl:template>

<xsl:template match="options/option">
  <option value="{@value|value}">
    <xsl:if test="selected[. = 'selected'] | @selected[. = 'selected']">
      <xsl:attribute name="selected">selected</xsl:attribute>
    </xsl:if>
    <xsl:value-of select="@text|text"/>
  </option>
</xsl:template>

<xsl:template match="single_select">
    <select name="{@name|name}{@index|index}">
        <xsl:if test="@disabled or disabled"><xsl:attribute
            name="disabled">disabled</xsl:attribute></xsl:if>
        <xsl:if test="@onchange or onchange">
          <xsl:attribute name="onchange"><xsl:value-of select="@onchange|onchange"/></xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="options/option"/>
    </select>
    <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="multi_select">
  <select multiple="multiple" name="{@name|name}{@index|index}">
    <xsl:if test="@disabled or disabled"><xsl:attribute
            name="disabled">disabled</xsl:attribute></xsl:if>
    <xsl:if test="@onclick or onclick">
      <xsl:attribute name="onclick"><xsl:value-of select="@onclick|onclick"/></xsl:attribute>
    </xsl:if>
    <xsl:apply-templates select="options/option"/>
  </select>
  <xsl:apply-templates select="error"/>
</xsl:template>

<xsl:template match="textarea">
    <textarea name="{@name|name}{@index|index}" cols="{@cols|cols}" rows="{@rows|rows}">
    <xsl:if test="@wrap|wrap"><xsl:attribute name="wrap">physical</xsl:attribute></xsl:if>
    <xsl:if test="@disabled or disabled"><xsl:attribute
            name="disabled">disabled</xsl:attribute></xsl:if>
    <xsl:if test="@onchange or onchange">
      <xsl:attribute name="onchange"><xsl:value-of select="@onchange|onchange"/></xsl:attribute>
    </xsl:if>
    <xsl:value-of select="@value|value"/>
    </textarea> <br />
    <xsl:apply-templates select="error"/>
</xsl:template>

</xsl:stylesheet>
