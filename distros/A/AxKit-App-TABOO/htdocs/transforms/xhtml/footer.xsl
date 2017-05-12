<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  exclude-result-prefixes="i18n texts"> 

  <xsl:param name="request.headers.host"/>

  <xsl:template name="CreateFooter">
    <div id="footer">
      <form method="get" action="http://www.google.com/search">
	<div class="fields">
	  <input type="text" name="q"/>
	  <input type="hidden" value="{substring-before($request.headers.host, ':')}" name="as_sitesearch"/>
	  <input type="submit" name="btnG">
	    <xsl:attribute name="value">	    
	      <xsl:value-of select="i18n:include('search')"/>
	    </xsl:attribute>
	  </input>
	</div>
      </form>
    </div>
  </xsl:template>
</xsl:stylesheet>