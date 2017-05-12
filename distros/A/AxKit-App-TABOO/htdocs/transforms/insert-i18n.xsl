<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:func="http://exslt.org/functions"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  extension-element-prefixes="func i18n"
  exclude-result-prefixes="func i18n texts">

  <xsl:param name="neg.lang">en</xsl:param>


  <xsl:template match="i18n:insert">
    <xsl:variable name="Text" select="."/>
    <xsl:value-of
      select="document(concat('/i18n.', $neg.lang, '.xml'))/texts:translations/texts:text[@id=$Text]"/>
  </xsl:template>

  <func:function name="i18n:include">  
    <xsl:param name="Text"/>
    <func:result 
      select="document(concat('/i18n.', $neg.lang, '.xml'))/texts:translations/texts:text[@id=$Text]"/>
  </func:function>

</xsl:stylesheet>