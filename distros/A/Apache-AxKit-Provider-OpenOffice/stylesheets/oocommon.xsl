<?xml version="1.0" encoding="ISO-8859-1"?> 

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:office="http://openoffice.org/2000/office" xmlns:style="http://openoffice.org/2000/style" xmlns:text="http://openoffice.org/2000/text" xmlns:table="http://openoffice.org/2000/table" xmlns:draw="http://openoffice.org/2000/drawing" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:number="http://openoffice.org/2000/datastyle" xmlns:svg="http://www.w3.org/2000/svg" xmlns:chart="http://openoffice.org/2000/chart" xmlns:dr3d="http://openoffice.org/2000/dr3d" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="http://openoffice.org/2000/form" xmlns:script="http://openoffice.org/2000/script" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="http://openoffice.org/2000/meta" exclude-result-prefixes="office style text table draw fo xlink number svg chart dr3d math form script dc meta">

<!-- global params -->
<xsl:param name="oo.request.uri"/> 
<xsl:param name="oo.sxwfile"/> 
 
<!-- convenience variables -->
<xsl:variable 
     name="meta" 
     select="document( concat( $oo.sxwfile, '/meta.xml'), /)/office:document-meta/office:meta"
 />

<xsl:variable 
     name="styles" 
     select="document( concat( $oo.sxwfile, '/styles.xml'), /)/office:document-styles/office:styles"
 />
 
<xsl:variable name="document-title">
  <xsl:choose>
    <xsl:when test="$meta/dc:title">
      <xsl:value-of select="$meta/dc:title"/>
    </xsl:when>
    <xsl:when test="/office:document/office:body/text:p[@text:style-name='Title']">
      <xsl:value-of select="/office:document/office:body/text:p[@text:style-name='Title'][1]"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>Untitled Document</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>
<!-- end convenience variables -->

<!-- begin functional templates -->


<xsl:template name="indent">
<xsl:param name="count">0</xsl:param>

  <xsl:if test="$count > 0">
    <xsl:text disable-output-escaping="yes">&#032;</xsl:text>
    <xsl:call-template name="indent">
      <xsl:with-param name="count" select="$count -1"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<!-- 
generic "commify" function. 
  accepts a flat nodelist and an optional string and
  returns the text from the nodes in the nodeset seperated by commas and whitespace
-->
<xsl:template name="commify">
  <xsl:param name="nodeset"/>
  <xsl:param name="string"></xsl:param>
  
  <xsl:choose>
    <xsl:when test="$nodeset">
      <xsl:call-template name="commify">
        <xsl:with-param name="nodeset"
                              select="$nodeset[position() != 1]"/>
        <xsl:with-param name="string">
        <xsl:choose>
          <xsl:when test="string-length( $string) > 0">
            <xsl:value-of select="concat($string, ', ', $nodeset[position()=1]/text())"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$nodeset[position()=1]/text()"/>
          </xsl:otherwise>
        </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$string"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>  

<xsl:template name="tokenize">
  <xsl:param name="string"/>
  <xsl:value-of select="translate(normalize-space($string), ' ', '-')"/>
</xsl:template>

<!-- convert centimeters to pixels (badly) -->
<xsl:template name="cm2px">
<xsl:param name="string"/>
  <xsl:choose>
    <xsl:when test="contains($string, 'cm')">
      <xsl:variable name="c" select="substring-before($string, 'cm')"/>
      <xsl:choose>
      <xsl:when test="string(number($c))='NaN'">
        <xsl:value-of select="$string"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat( string( ceiling( number($c) div 2.55 * 72)) , 'px')"/>
      </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$string"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
<!-- end functional templates -->
</xsl:stylesheet>
