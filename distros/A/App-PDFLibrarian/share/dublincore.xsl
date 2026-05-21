<?xml version="1.0"?>
<!--
  Modified from BibTeXML: http://bibtexml.sourceforge.net/
  License: http://creativecommons.org/licenses/GPL/2.0/
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:bibtex="http://bibtexml.sf.net/"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:dc="http://purl.org/dc/elements/1.1/" >
  <xsl:output method="xml" indent="yes" />

<!--
  list of DublinCore elements:

  title, creator, contributor, subject, description,
  publisher, date, identifier, type, format, source,
  language, relation, coverage, rights

  http://dublincore.org/documents/usageguide/elements.shtml
-->

<xsl:template match="/">
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:dc="http://purl.org/dc/elements/1.1/">
    <xsl:apply-templates />
  </rdf:RDF>
</xsl:template>

<xsl:template match="bibtex:entry">
  <rdf:Description rdf:about="#{@id}">
    <xsl:apply-templates />
  </rdf:Description>
</xsl:template>

<xsl:template match="bibtex:entry/*">

  <dc:title>
    <xsl:choose>
      <xsl:when test="bibtex:chapter">
        <xsl:choose>
          <xsl:when test="bibtex:chapter/bibtex:title">
            <xsl:value-of select="normalize-space(
                                  bibtex:chapter/bibtex:title)"/>
            <xsl:if test="bibtex:chapter/bibtex:subtitle">
              <xsl:text>: </xsl:text>
              <xsl:value-of select="normalize-space(
                                    bibtex:chapter/bibtex:subtitle)"/>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="normalize-space(bibtex:chapter)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="bibtex:title/bibtex:title">
        <xsl:value-of select="normalize-space(bibtex:title/bibtex:title)"/>
        <xsl:if test="bibtex:title/bibtex:title">
          <xsl:text>: </xsl:text>
          <xsl:value-of select="normalize-space(bibtex:title/bibtex:subtitle)"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space(bibtex:title)"/>
      </xsl:otherwise>
    </xsl:choose>
  </dc:title>

  <xsl:choose>
    <xsl:when test="bibtex:author/bibtex:person">
      <xsl:for-each select="bibtex:author/bibtex:person">
        <dc:creator>
          <xsl:value-of select="normalize-space(.)"/>
        </dc:creator>
      </xsl:for-each>
    </xsl:when>
    <xsl:when test="bibtex:editor/bibtex:person">
      <xsl:for-each select="bibtex:editor/bibtex:person">
        <dc:creator>
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text> (ed.)</xsl:text>
        </dc:creator>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="bibtex:author">
        <dc:creator>
          <xsl:value-of select="normalize-space(.)"/>
        </dc:creator>
      </xsl:for-each>
      <xsl:for-each select="bibtex:editor">
        <dc:creator>
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:text> (ed.)</xsl:text>
        </dc:creator>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>

  <dc:date>
    <!--<xsl:text>c</xsl:text>-->
    <xsl:value-of select="bibtex:year"/>
  </dc:date>

  <xsl:apply-templates />

  <xsl:if test="bibtex:chapter">
    <dc:source>
      <xsl:value-of select="normalize-space(bibtex:title)"/>
    </dc:source>
  </xsl:if>

  <dc:type>
    <!--<xsl:value-of select='name()'/>-->
    <xsl:value-of select='substring-after(name(),"bibtex:")'/>
  </dc:type>

</xsl:template>


  <xsl:template match="bibtex:abstract">
    <dc:description>
      <xsl:value-of select="."/>
    </dc:description>
  </xsl:template>

  <xsl:template match="bibtex:keywords|bibtex:category">
    <!-- dc:coverage -->
    <xsl:choose>
      <xsl:when test="bibtex:keyword">
        <xsl:for-each select="*">
          <dc:subject>
            <xsl:value-of select="."/>
          </dc:subject>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <dc:subject>
          <xsl:value-of select="."/>
        </dc:subject>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="bibtex:language">
    <dc:language>
      <xsl:value-of select="."/>
    </dc:language>
  </xsl:template>

  <xsl:template match="bibtex:isbn|bibtex:issn|bibtex:doi|
                       bibtex:lccn|bibtex:mrnumber">
    <dc:identifier>
      <xsl:value-of select='substring-after(name(),"bibtex:")'/>
      <xsl:text>:</xsl:text>
      <xsl:value-of select="."/>
    </dc:identifier>
  </xsl:template>

  <xsl:template match="bibtex:url">
    <dc:identifier rdf:resource="{.}"/>
  </xsl:template>

  <xsl:template match="bibtex:howpublished">
    <!--
        special case for the often used
        howpublished = "\url{http://www.example.com/}",
    -->
    <xsl:if test="contains(.,'\url')">
      <dc:identifier rdf:resource="{substring-after(.,'\url')}"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="bibtex:publisher|bibtex:organization|
                       bibtex:institution|bibtex:school">
    <dc:publisher>
      <xsl:if test="../bibtex:address">
        <xsl:value-of select="../bibtex:address"/>
        <xsl:text>: </xsl:text>
      </xsl:if>
      <xsl:value-of select="normalize-space(.)"/>
    </dc:publisher>
  </xsl:template>

  <xsl:template match="bibtex:article/bibtex:journal">
    <dc:source>
      <xsl:value-of select="../bibtex:journal"/>
      <xsl:text>, vol.</xsl:text>
      <xsl:value-of select='../bibtex:volume'/>
      <xsl:text>, no.</xsl:text>
      <xsl:value-of select='../bibtex:number'/>
      <xsl:text>, pp.</xsl:text>
      <xsl:value-of select='../bibtex:pages'/>
    </dc:source>
  </xsl:template>

  <xsl:template match="bibtex:booktitle">
    <dc:source>
      <xsl:value-of select="normalize-space(.)"/>
    </dc:source>
  </xsl:template>


  <xsl:template match="bibtex:copyright">
    <dc:rights>
      <xsl:value-of select="normalize-space(.)"/>
    </dc:rights>
  </xsl:template>

  <xsl:template match="bibtex:type">
    <dc:type>
      <xsl:value-of select="."/>
    </dc:type>
  </xsl:template>

  <xsl:template match="bibtex:size">
    <dc:format>
      <xsl:value-of select="."/>
    </dc:format>
  </xsl:template>


  <xsl:template match="text()" />


</xsl:stylesheet>
