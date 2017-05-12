<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">

<xsl:template match="article">
  <xsl:apply-templates mode="docbook"/>
</xsl:template>
  
<xsl:template match="abstract" mode="docbook">
    
</xsl:template>

<xsl:template match="section" mode="docbook">
  <div class="section">
    <xsl:attribute name="id">
      <xsl:choose>
        <xsl:when test="@label">
          <xsl:value-of select="@label"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="translate(title, ' -)(?:&#xA;', '')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>

    <xsl:element name="h{number( count(ancestor-or-self::section) + 1)}">
      <a name="{translate(title, ' -)(?:&#xA;', '')}">
        <xsl:apply-templates mode="docbook" select="title"/>
      </a>
    </xsl:element>

  <xsl:apply-templates mode="docbook" select="*[local-name() != 'title']"/>
  
 </div>
 <hr/> 
</xsl:template>

<xsl:template match="para" mode="docbook">
  <p>
    <xsl:apply-templates mode="docbook"/>
  </p>
</xsl:template>

<xsl:template match="itemizedlist" mode="docbook">
  <ul>
    <xsl:apply-templates mode="docbook"/>
  </ul>
</xsl:template>

<xsl:template match="orderedlist" mode="docbook">
  <ol>
    <xsl:apply-templates mode="docbook"/>
  </ol>
</xsl:template>

<xsl:template match="listitem" mode="docbook">
  <li>
    <xsl:apply-templates mode="docbook"/>
  </li>
</xsl:template>

<xsl:template match="ulink" mode="docbook">
  <a href="{@url}">
    <xsl:apply-templates mode="docbook"/>
  </a><img src="/img/out.png"/>
</xsl:template>

<xsl:template match="xref" mode="docbook">
  <a href="#{@linkend}">
    <xsl:apply-templates mode="docbook"/>
  </a>
</xsl:template>


<xsl:template match="programlisting" mode="docbook">
  <div class="programlisting">
    <pre class="verbatim">
    <xsl:apply-templates mode="docbook"/>
    </pre>
  </div>
</xsl:template>

<xsl:template match="filename | userinput | computeroutput | literal" mode="docbook">
  <code>
    <xsl:apply-templates mode="docbook"/>
  </code>
</xsl:template>

<xsl:template match="literallayout" mode="docbook">
  <pre class="verbatim">
    <xsl:apply-templates mode="docbook"/>
  </pre>
</xsl:template>

<xsl:template match="emphasis" mode="docbook">
  <em>
    <xsl:apply-templates mode="docbook"/>
  </em>
</xsl:template>

<xsl:template match="blockquote" mode="docbook">
  <blockquote>
    <xsl:apply-templates mode="docbook"/>
  </blockquote>
</xsl:template>

<xsl:template match="inlinemediaobject" mode="docbook">
  <span class="mediaobject">
      <xsl:apply-templates mode="docbook"/>
  </span>
</xsl:template>

<xsl:template match="mediaobject" mode="docbook">
  <div class="mediaobject">
      <xsl:apply-templates mode="docbook"/>
  </div>
</xsl:template>

<xsl:template match="imageobject" mode="docbook">
    <img src="{imagedata/@fileref}"/>
</xsl:template>

<!--the "css forwarder" template
    These are the sdocbook elements
    for which there is no reasonable
    HTML counterpart structure but to
    which a designer may want to add some
    visual distiction via CSS -->

<xsl:template match="authorinitials">
  <span class="{name()}">
    <xsl:apply-templates/>
  </span>
</xsl:template>

<!--the "vanilla" template
    these are the sdocbook elements
    for which there is no reasonable
    HTML counterpart or straightforward
    meaningful visual format -->

<xsl:template match="honorific" mode="docbook">
    <xsl:apply-templates mode="docbook"/>
</xsl:template>

<xsl:template match="section/title" mode="docbook">
  <xsl:apply-templates mode="docbook"/>
</xsl:template>

<xsl:template match="article/title" mode="docbook">
  <h1>
    <xsl:apply-templates mode="docbook"/>
  </h1>
  <hr/>
</xsl:template>

<xsl:template match="title" mode="docbook"></xsl:template>

<xsl:template match="/article/articleinfo/*" mode="docbook"></xsl:template>
<!-- end core sdocbook elements -->

</xsl:stylesheet>
