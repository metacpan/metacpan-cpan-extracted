<?xml version="1.0"?>
<xsl:stylesheet
	       version="1.0"
   	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:param name="request.uri"/>

<xsl:template match="/xspwiki/page"/>
<xsl:template match="/xspwiki/db"/>

<xsl:template match="xspwiki">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="edit">
    <form action="{substring-before($request.uri, '/view/')}/edit/{substring-after($request.uri, '/view/')}" method="POST" enctype="application/x-www-form-urlencoded">
  <input type="hidden" name="action" value="save"/>
  <h1><xsl:value-of select="/xspwiki/page"/> : 
  <input type="submit" value=" Save "/> <input type="submit" name="preview" value=" Preview "/></h1>
  <textarea name="text" style="width:100%" rows="18" cols="80" wrap="virtual">
    <xsl:value-of select="string(./text)"/>
  </textarea>
  <xsl:apply-templates select="./texttypes"/>
</form>
</xsl:template>

<xsl:template match="texttypes">
  Text Type: 
  <select name="texttype">
    <xsl:apply-templates/>
  </select>
</xsl:template>

<xsl:template match="texttype">
  <option value="{@id}">
  <xsl:if test="@selected">
  	  <xsl:attribute name="selected">selected</xsl:attribute>
  </xsl:if>
  	  <xsl:apply-templates/>
  </option>
</xsl:template>

<xsl:template match="history">
  <h1>History for <xsl:value-of select="/xspwiki/page"/></h1>
  <table>
      <tr><th>Page</th><th>Date</th><th>IP Address</th><th>Bytes</th></tr>
      <xsl:apply-templates select="./entry"/>
  </table>
</xsl:template>

<xsl:template match="history/entry">
  <tr>
    <xsl:apply-templates/>
  </tr>
</xsl:template>

<xsl:template match="history/entry/id">
</xsl:template>

<xsl:template match="history/entry/page">
    <td>
        <i><xsl:apply-templates/></i>
    </td>
</xsl:template>

<xsl:template match="history/entry/modified">
  <td><a href="./{/xspwiki/page}?action=historypage;id={../id}"><xsl:apply-templates/></a></td>
</xsl:template>

<xsl:template match="history/entry/ip-address">
  <td><xsl:apply-templates/></td>
</xsl:template>

<xsl:template match="history/entry/bytes">
  <td><xsl:apply-templates/></td>
</xsl:template>

<xsl:template match="search-results">
  <h1>Search Results</h1>
  <xsl:choose>
    <xsl:when test="./result">
      Your query for <em>'<xsl:value-of select="$q"/>'</em> returned hits on the following pages:
        <xsl:apply-templates/>
    </xsl:when>
    <xsl:otherwise>
      No match found for <em>'<xsl:value-of select="$q"/>'</em>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="search-results/result">
  <div class="search-result">
  <a href="{page/text()}"><xsl:apply-templates select="page"/></a>
  </div>
</xsl:template>

<xsl:template match="newpage">
  <i>This page has not yet been created</i>
</xsl:template>

<!-- useful for testing - commented out for live
<xsl:template match="node()|@*">
  <xsl:copy>
   <xsl:apply-templates select="@*"/>
   <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>
-->

</xsl:stylesheet>
