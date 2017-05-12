<?xml version="1.0"?>
<xsl:stylesheet
               version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:template match="sidemenu" mode="sidemenu">
 <xsl:apply-templates mode="sidemenu"/>
</xsl:template>

<xsl:template match="menu" mode="sidemenu">
 <div class="sidemenumenu">
  <xsl:apply-templates mode="sidemenu"/>
 </div>
</xsl:template>

<xsl:template match="title" mode="sidemenu">
 <div class="sidemenutitle">
  <xsl:apply-templates mode="sidemenu"/>
 </div>
</xsl:template>

<xsl:template match="item" mode="sidemenu">
 <div class="sidemenuitem">
  <a href="{@url}"><img src="/img/arrow.gif" border="0"/><xsl:apply-templates mode="sidemenu"/></a>
 </div>
</xsl:template>

</xsl:stylesheet>
