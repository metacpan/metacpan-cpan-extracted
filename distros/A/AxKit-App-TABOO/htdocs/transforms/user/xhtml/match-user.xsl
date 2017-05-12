<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  exclude-result-prefixes="user i18n">
 
  <xsl:template match="user:user">
    <h2><xsl:value-of select="./user:name"/></h2>
    <dl>

      <dt>
	<xsl:value-of select="i18n:include('username')"/>
      </dt>
      <dd><xsl:value-of select="./user:username"/></dd>

      <dt>
	<xsl:value-of select="i18n:include('user-email')"/>
      </dt>
      <dd>
	<a href="mailto:{./user:email}">
	  <xsl:value-of select="./user:email"/>
	</a>
      </dd>

      <dt>
	<xsl:value-of select="i18n:include('homepage')"/>
      </dt>
      <dd>
	<a href="{./user:uri}">
	  <xsl:value-of select="./user:uri"/>
	</a>
      </dd>


      <dt>
	<xsl:value-of select="i18n:include('user-bio')"/>	
      </dt>
      <dd><xsl:value-of select="./user:bio"/></dd>
    </dl>
  </xsl:template>
</xsl:stylesheet>
