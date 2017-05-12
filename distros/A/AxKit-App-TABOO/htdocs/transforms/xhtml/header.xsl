<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:atom="http://www.w3.org/2005/10/23/Atom#"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  exclude-result-prefixes="rdf atom i18n dc"> 

  <xsl:template name="CommonHTMLHead">
    <link rel="stylesheet" type="text/css" href="/css/basic.css"/>
  </xsl:template>

  <xsl:template name="CreateHeader">
    <div id="top" class="main-header">
      <h1>
	<a rel="top" href="/">
	  <xsl:value-of
	    select="document('/site/main.rdf')/rdf:RDF/rdf:Description/dc:title/rdf:Alt/rdf:_1"/>
	</a>
      </h1>
      <p class="slogan">
	<xsl:value-of
	  select="document('/site/main.rdf')/rdf:RDF/rdf:Description/atom:subtitle"/>
      </p>
    </div>
  </xsl:template>

</xsl:stylesheet>