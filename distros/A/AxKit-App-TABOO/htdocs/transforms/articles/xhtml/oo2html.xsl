<?xml version="1.0" encoding="ISO-8859-1"?> 
<xsl:stylesheet version="1.0" 
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
     xmlns:office="http://openoffice.org/2000/office" 
     xmlns:style="http://openoffice.org/2000/style" 
     xmlns:text="http://openoffice.org/2000/text" 
     xmlns:table="http://openoffice.org/2000/table" 
     xmlns:draw="http://openoffice.org/2000/drawing" 
     xmlns:fo="http://www.w3.org/1999/XSL/Format" 
     xmlns:xlink="http://www.w3.org/1999/xlink" 
     xmlns:number="http://openoffice.org/2000/datastyle" 
     xmlns:svg="http://www.w3.org/2000/svg" xmlns:chart="http://openoffice.org/2000/chart" xmlns:dr3d="http://openoffice.org/2000/dr3d" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="http://openoffice.org/2000/form" xmlns:script="http://openoffice.org/2000/script" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="http://openoffice.org/2000/meta" exclude-result-prefixes="office style text table draw fo xlink number svg chart dr3d math form script dc meta">
<xsl:import href="oocommon.xsl"/>
<xsl:output method="html" indent="yes" encoding="ISO-8859-1"/>

<!-- User-editable configuration -->

<!-- xsl:variable name="css-file">screen.css</xsl:variable>
<xsl:variable name="css-file"/>-->
<!-- end user configuration -->

<!-- xsl:template match="/">
  <xsl:apply-templates select="office:document-content/office:body"/>
</xsl:template>
<end root template -->


<!--body -->
<xsl:template match="office:body">
<body>
  <xsl:apply-templates/>
  <xsl:call-template name="notes"/>
</body>
</xsl:template>

<!-- paragraph styles -->

<xsl:template match="text:p">
<p>
 <xsl:attribute name="class">
 <xsl:call-template name="tokenize">
   <xsl:with-param name="string" select="@text:style-name"/>
 </xsl:call-template>
 </xsl:attribute>
  <xsl:apply-templates/>
</p>
</xsl:template>

<!-- headers -->
<xsl:template match="text:h">
<xsl:element name="{concat( 'h', @text:level )}">
  <xsl:attribute name="class"> 
    <xsl:call-template name="tokenize">
      <xsl:with-param name="string" select="@text:style-name"/>
    </xsl:call-template>
  </xsl:attribute>
  <!-- generate the named anchor if there is a TOC and no reference mark -->
   <xsl:choose>
   <xsl:when test="/office:document-content/office:body/text:table-of-content and 
                 not(text:reference-mark-start)">
     <a name="{generate-id(.)}">
       <xsl:apply-templates/>
     </a>
   </xsl:when>
   <xsl:otherwise>
    <xsl:apply-templates/>
   </xsl:otherwise>
   </xsl:choose>
</xsl:element>
</xsl:template>

<xsl:template match="text:span">
<span>
 <xsl:attribute name="class">
 <xsl:call-template name="tokenize">
   <xsl:with-param name="string" select="@text:style-name"/>
 </xsl:call-template>
 </xsl:attribute>
  <xsl:apply-templates/>
</span>
</xsl:template>

<!-- images -->
<xsl:template match="draw:image">
  <img src="{concat( $oo.sxwfile, '/', substring-after( @xlink:href, '#' ) )}"/>
</xsl:template>

<!-- end images -->

<!-- list groups -->

<xsl:template match="text:unordered-list">
<ul>
  <xsl:apply-templates/>
</ul>
</xsl:template>

<xsl:template match="text:ordered-list">
<ol>
  <xsl:apply-templates/>
</ol>
</xsl:template>

<xsl:template match="text:list-item">
<li>
  <xsl:apply-templates/>
</li>
</xsl:template>
<!-- end list groups -->

<!-- style-to-element mappings -->

<xsl:template match="text:p[@text:style-name='Preformatted Text']">
<pre>
  <xsl:apply-templates/>
</pre>
</xsl:template>

<xsl:template match="text:p[@text:style-name='Preformatted Text']/text:tab-stop">
<xsl:text  disable-output-escaping="yes">&#032;&#032;&#032;&#032;</xsl:text>
</xsl:template>

<xsl:template match="text:p[@text:style-name='Preformatted Text']/text:s" name="space">
  <xsl:call-template name="indent">
    <xsl:with-param name="count" select="@text:c + 1"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="text:p[@text:style-name='Preformatted Text']/text:line-break">
  <xsl:text disable-output-escaping="yes">&#013;</xsl:text>
</xsl:template>

<xsl:template match="text:p[@text:style-name='Horizontal Line']">
  <hr/>
</xsl:template>

<xsl:template match="text:p[@text:style-name='Quotations']">
  <blockquote><xsl:apply-templates/></blockquote>
</xsl:template>

<xsl:template match="text:span[@text:style-name='Emphasis' or @text:style-name='T2']">
  <em><xsl:apply-templates/></em>
</xsl:template>

<xsl:template match="text:span[@text:style-name='Strong Emphasis' or @text:style-name='T1']">
  <strong><xsl:apply-templates/></strong>
</xsl:template>

<xsl:template match="text:span[@text:style-name='Citation']">
  <cite><xsl:apply-templates/></cite>
</xsl:template>

<!-- end style-to-element mappings --> 

<!-- footnotes and endnotes -->

<xsl:template match="text:footnote|text:endnote">
<a name="body{@text:id}" href="#{@text:id}">
  [<xsl:value-of select="text:footnote-citation|text:endnote-citation"/>]
</a>
</xsl:template>

<xsl:template match="text:footnote-citation|text:endnote-citation"/>

<xsl:template match="text:p[@text:style-name='Footnote' or @text:style-name='Endnote']" 
              mode="notes">
<p>
  <a name="{ancestor::text:footnote/@text:id|ancestor::text:endnote/@text:id}">
    [<a href="#body{ancestor::text:footnote/@text:id|ancestor::text:endnote/@text:id}"><xsl:value-of select="ancestor::text:footnote/text:footnote-citation|ancestor::text:endnote/text:endnote-citation"/></a>]
    <xsl:apply-templates/>
  </a>
</p>
</xsl:template>

<xsl:template name="notes">
<xsl:variable name="ftn" select="/office:document-content/office:body//text:p[@text:style-name='Footnote' or @text:style-name='Endnote']"/>
  <xsl:if test="count($ftn) > 0 ">
    <hr/>
    <xsl:apply-templates select="$ftn" mode="notes"/>
  </xsl:if>
</xsl:template>
<!-- end footnotes and endnotes -->

<!-- links -->
<xsl:template match="text:reference-mark|text:bookmark|text:reference-mark-start|text:bookmark-start">
  <a name="@text:name"/>
</xsl:template>

<xsl:template match="text:reference-ref|text:bookmark-ref">
<a href="#{@text:ref-name}">
  <xsl:apply-templates/>
</a>
</xsl:template>

<xsl:template match="text:a">
<a href="{@xlink:href}">
  <xsl:apply-templates/>
</a>
</xsl:template>

<!-- end links -->

<xsl:template name="styles2string">
<xsl:param name="style"/>
  <xsl:for-each select="$style/style:properties">
    <xsl:for-each select="@*">
    <xsl:value-of select="local-name()"/>: <xsl:value-of select="."/>;
    </xsl:for-each>
  </xsl:for-each>
</xsl:template>

<!-- tables -->

<xsl:template match="table:table">
<xsl:variable name="style-name" select="@table:style-name"/>
<table>
  <xsl:attribute name="style">{ 
  <xsl:call-template name="styles2string">
    <xsl:with-param name="style" select="/office:document-content/office:automatic-styles/style:style[@style:name=$style-name]"/>
  </xsl:call-template> }
  </xsl:attribute>
 <xsl:attribute name="class">
 <xsl:call-template name="tokenize">
   <xsl:with-param name="string" select="@table:style-name"/>
 </xsl:call-template>
 </xsl:attribute>
  <xsl:apply-templates/>
</table>
</xsl:template>

<xsl:template match="table:table-row">
<tr>
  <xsl:apply-templates/>
</tr>
</xsl:template>

<xsl:template match="table:table-cell">
<xsl:variable name="style-name" select="@table:style-name"/>
<td>
  <xsl:attribute name="style">{ 
  <xsl:call-template name="styles2string">
    <xsl:with-param name="style" select="/office:document-content/office:automatic-styles/style:style[@style:name=$style-name]"/>
  </xsl:call-template> }
  </xsl:attribute>
 <xsl:attribute name="class">
 <xsl:call-template name="tokenize">
   <xsl:with-param name="string" select="@table:style-name"/>
 </xsl:call-template>
 </xsl:attribute>
  <xsl:apply-templates/>
</td>
</xsl:template>

<!-- end table templates -->

<!-- bibliography templates -->

<xsl:template match="text:bibliography/text:index-body">
<div>
 <xsl:attribute name="class">
 <xsl:call-template name="tokenize">
   <xsl:with-param name="string" select="@text:style-name"/>
 </xsl:call-template>
 </xsl:attribute>
  <xsl:apply-templates/>
</div>
</xsl:template>

<xsl:template match="text:bibliography-mark">
<xsl:choose>
  <xsl:when test="@text:url">
  <a href="{@text:url}">
    <xsl:apply-templates/>
  </a>
  </xsl:when>
  <xsl:otherwise>
    <xsl:apply-templates/>
  </xsl:otherwise>
</xsl:choose>
</xsl:template>

<!-- end bibliography -->

<!-- toc generator -->
<xsl:template match="office:body/text:table-of-content">
<div class="toc">
  <xsl:for-each select="/office:document-content/office:body//text:h">
    <div style="margin: 0px 0px 2px {@text:level * 24}px;">
       <a>
         <xsl:attribute name="href">
           <xsl:choose>
           <xsl:when test="text:reference-mark-start">
             <xsl:value-of select="concat( '#', text:reference-mark-start/@text:name )"/>
           </xsl:when>
           <xsl:otherwise>
             <xsl:value-of select="concat( '#', generate-id(.) )"/>
           </xsl:otherwise>
           </xsl:choose>
         </xsl:attribute>
         <xsl:value-of select="."/>
       </a>
    </div>
  </xsl:for-each>
</div>
</xsl:template>

<!-- end toc generator -->

<!-- no-ops -->
<xsl:template match="text:table-of-content-entry-template"/>
<xsl:template match="text:bibliography-source"/>
<xsl:template match="text:reference-mark-end|text:bookmark-end"/>
<xsl:template match="style:*"/>
<xsl:template match="meta:*"/>
<xsl:template match="dc:*"/>
<!-- end no-op templates -->

</xsl:stylesheet>
