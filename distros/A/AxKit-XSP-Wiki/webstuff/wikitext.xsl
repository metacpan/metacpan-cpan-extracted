<?xml version="1.0"?>
<xsl:stylesheet
	       version="1.0"
   	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

  <xsl:template match="wiki">
    <xsl:apply-templates mode="wiki"/>
  </xsl:template>
  
  <xsl:template match="br" mode="wiki">
    <br/>
  </xsl:template>
  
  <xsl:template match="link" mode="wiki">
    <a href="{@href}"><xsl:apply-templates mode="wiki"/></a>
    <xsl:if test="contains(@href, 'http:')">
      <img src="/img/out.png"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="strong" mode="wiki">
    <strong><xsl:apply-templates mode="wiki"/></strong>
  </xsl:template>

  <xsl:template match="em" mode="wiki">
    <em><xsl:apply-templates mode="wiki"/></em>
  </xsl:template>
  
  <xsl:template match="hr" mode="wiki">
    <hr/>
  </xsl:template>
  
  <xsl:template match="code" mode="wiki">
    <pre class="verbatim"><xsl:apply-templates mode="wiki"/></pre>
  </xsl:template>
  
  <xsl:template match="orderedlist" mode="wiki">
    <ol><xsl:apply-templates mode="wiki"/></ol>
  </xsl:template>
  
  <xsl:template match="itemizedlist" mode="wiki">
    <ul><xsl:apply-templates mode="wiki"/></ul>
  </xsl:template>
  
  <xsl:template match="listitem" mode="wiki">
    <listitem><xsl:apply-templates mode="wiki"/></listitem>
  </xsl:template>
  
</xsl:stylesheet>
