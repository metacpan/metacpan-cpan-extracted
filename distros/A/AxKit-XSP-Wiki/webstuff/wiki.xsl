<?xml version="1.0"?>
<xsl:stylesheet
	       version="1.0"
   	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:include href="wikitags.xsl"/>
<xsl:include href="pod.xsl"/>
<xsl:include href="wikitext.xsl"/>
<xsl:include href="docbook.xsl"/>
<xsl:include href="sidemenu.xsl"/>

<xsl:output method="html" doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"/>

<xsl:param name="action" select="'view'"/>
<xsl:param name="request.uri"/>

<xsl:template match="/">
  <xsl:variable name="side-menu-uri" select="concat('axkit:/wiki/view/', string(/xspwiki/db), '/SideMenu')"/>
    <html>
      <head>
        <title>AxKit Wiki - <xsl:value-of select="/xspwiki/page"/></title>
	<link rel="stylesheet" href="/wiki/wiki.css"
              type="text/css" media="screen" />
      </head>
	
      <body>
       <div class="header">
        <table width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
         <td width="50%"><img src="/img/axon-logo.png" alt="logo"/></td>
         <td width="50%" align="right">
          <div class="searchbanner">
           <form action="./{/xspwiki/page}" method="GET">
            <input type="hidden" name="action" value="search"/>
            <input type="text" name="q" maxlength="255" size="20"/>
            <input type="submit" value=" Search "/>
           </form>
          </div>
         </td> 
        </tr></table>
       </div>
        
       <div class="main-content">
        <table><tr><td valign="top" width="160">
        <div class="sidemenu">
         <xsl:apply-templates select="document('/wiki/sidemenu.xml')" mode="sidemenu"/>
        </div></td><td valign="top" width="80%">
        <div class="maincontent">
         <div class="breadcrumbs">
          <a href="/"><xsl:value-of select="/xspwiki/db"/></a> :: <a href="DefaultPage">Wiki</a> :: <xsl:value-of select="/xspwiki/page"/>
         </div>
         <hr/>
         <div class="content">
          <xsl:choose>
           <xsl:when test="$action='historypage'">
           <h1>History View</h1>
           <div class="ipaddress">IP: <xsl:value-of select="/xspwiki/processing-instruction('ip-address')"/></div>
           <div class="date">Date: <xsl:value-of select="/xspwiki/processing-instruction('modified')"/></div>
           <hr/>
           </xsl:when>
          </xsl:choose>
       
         <xsl:apply-templates select="/xspwiki/main-content"/>
        
	<xsl:choose>
	  <xsl:when test="$action='view'">
	    <hr/>
	    <a href="./{/xspwiki/page}?action=edit">Edit This Page</a>
            / <a href="./{/xspwiki/page}?action=history">Show Page History</a>
	  </xsl:when>
	  <xsl:when test="$action='edit'">
	    <hr/>
  	    <p><a href="EditTips">EditTips</a></p>
	  </xsl:when>
          <xsl:when test="$action='historypage'">
	    <hr/>
            <form action="{substring-before($request.uri, '/view/')}/edit/{substring-after($request.uri, '/view/')}" method="POST" enctype="application/x-www-form-urlencoded">
           <input type="hidden" name="action" value="restore"/>
           <input type="hidden" name="id" value="{$id}"/>
           <input type="submit" name="Submit" value="Restore This Version"/>
          </form>
          </xsl:when>
          <xsl:when test="$action='history'">
	    <hr/>
          </xsl:when>
          <xsl:when test="$action='search'">
              <hr/>
              <div class="search">
              <form action="./{/xspwiki/page}" method="GET">
                  <input type="hidden" name="action" value="search"/>
                  <input type="text" name="q" maxlength="255" size="20" value="{$q}"/>
                  <input type="submit" value=" Search "/>
              </form>
              </div>
          </xsl:when>
	  <xsl:otherwise>
	  Other Mode?
	  </xsl:otherwise>
	</xsl:choose>
          <hr/>
          
         </div> <!-- content -->	
        </div> <!-- maincontent -->
        </td></tr></table>
       </div> <!-- base -->
      </body>
	
    </html>
</xsl:template>

</xsl:stylesheet>
