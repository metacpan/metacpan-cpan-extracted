<?xml version="1.0"?>
<xsl:stylesheet
	       version="1.0"
   	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:template match="pod">
 <xsl:apply-templates mode="pod"/>
</xsl:template>

<xsl:template match="para" mode="pod">
  <p><xsl:apply-templates mode="pod"/></p>
</xsl:template>

<xsl:template match="verbatim" mode="pod">
  <pre class="verbatim"><xsl:apply-templates mode="pod"/></pre>
</xsl:template>

<xsl:template match="link" mode="pod">
  <xsl:choose>
    <xsl:when test='string-length(@section) and not( string-length(@page) )'>
      <a href="#{@section}"><xsl:apply-templates mode="pod"/></a>
    </xsl:when>
    <xsl:otherwise>
      <a href="./{@page}#{@section}"><xsl:apply-templates mode="pod"/></a>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xlink" mode="pod">
  <a href="{@href}"><xsl:apply-templates mode="pod"/></a><img src="/img/out.png"/>
</xsl:template>

<xsl:template match="head1" mode="pod">
  <h1><a name="{.}"><xsl:apply-templates mode="pod"/></a></h1>
</xsl:template>

<xsl:template match="head2" mode="pod">
  <h2><a name="{.}"><xsl:apply-templates mode="pod"/></a></h2>
</xsl:template>

<xsl:template match="head3" mode="pod">
  <h3><a name="{.}"><xsl:apply-templates mode="pod"/></a></h3>
</xsl:template>

<xsl:template match="head4" mode="pod">
  <h4><a name="{.}"><xsl:apply-templates mode="pod"/></a></h4>
</xsl:template>

<xsl:template match="itemizedlist" mode="pod">
  <ul><xsl:apply-templates mode="pod"/></ul>
</xsl:template>

<xsl:template match="orderedlist" mode="pod">
  <ol><xsl:apply-templates mode="pod"/></ol>
</xsl:template>

<xsl:template match="listitem" mode="pod">
  <li><xsl:apply-templates mode="pod"/></li>
</xsl:template>

<xsl:template match="itemtext" mode="pod">
  <span class="itemtext"><xsl:apply-templates mode="pod"/></span>
</xsl:template>

<xsl:template match="hr" mode="pod">
  <hr/>
</xsl:template>

<xsl:template match="C" mode="pod">
  <code><xsl:apply-templates mode="pod"/></code>
</xsl:template>

<xsl:template match="B" mode="pod">
  <b><xsl:apply-templates mode="pod"/></b>
</xsl:template>

<xsl:template match="I" mode="pod">
  <i><xsl:apply-templates mode="pod"/></i>
</xsl:template>

<xsl:template match="F" mode="pod">
  <literal><xsl:apply-templates mode="pod"/></literal>
</xsl:template>

</xsl:stylesheet>
