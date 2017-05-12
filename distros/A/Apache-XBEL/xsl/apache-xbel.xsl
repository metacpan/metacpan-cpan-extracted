<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
		xmlns:asc="urn:aaronstraupcope:apache:xbel"
		xmlns:doc="http://xsltsl.org/xsl/documentation/1.0"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:x="http://pyxml.sourceforge.net/topics/xbel/"
                xmlns:xml="http://www.w3.org/XML/1998/namespace"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		exclude-result-prefixes = "asc doc h x"
		version="1.0">

<!-- ====================================================================== 

     ====================================================================== -->

     <doc:reference>
      <referenceinfo>

       <title>apache-xbel.xsl</title>

       <abstract>
        <para>This is an <acronym>XSLT</acronym> stylesheet for
        transforming XBEL 1.0 documents in XHTML 1.1 documents</para>
       </abstract>

       <author>
	<surname>Cope</surname>
	<firstname>Aaron</firstname>
	<othername>Straup</othername>
       </author>

       <legalnotice>
	<para>This is based on work originally developed by Joris
	Graaumans http://www.cs.ruu.nl/~joris/stuff.html</para>		 

        <para>This work is licensed under the Creative Commons
        Attribution-ShareAlike License. To view a copy of this
        license, visit http://creativecommons.org/licenses/by-sa/1.0/
        or send a letter to Creative Commons, 559 Nathan Abbott Way,
        Stanford, California 94305, USA.</para> 
       </legalnotice>

       <revhistory>
        <revision>
	 <revnumber>1.2</revnumber>
	 <date>March 01, 2004</date>
	 <revremark>
	  <para>Replaced numeric IDs for folders with XBEL folder/@id
        and added hooks to toggle display for root element when
        displaying a slice.</para>
         </revremark>
	</revision>
       </revhistory>

      </referenceinfo>

      <partintro>
       <section>
        <title>Usage</title>
	<para>Consult the documentation for your favourite
       <acronym>XSLT</acronym> processor.</para>

       <para>This stylesheet accepts two parameters, both of which are
       optional:</para>

       <itemizedlist>
        <listitem>
	 <formalpara>
	  <title>base</title>
	  <para>String. If defined, this value will be used to set the
        value of '/html/head/base'.</para>
	 </formalpara>
	</listitem>
        <listitem>
	 <formalpara>
	  <title>lang</title>
	  <para>String. If defined, this value will be used to set the
        value of '/html[@xml:lang]'.</para>
	 </formalpara>
	</listitem>
        <listitem>
	 <formalpara>
	  <title>disable-output-escaping</title>
	  <para>Boolean. If defined, output-escaping will be disabled
        for title and description nodes.</para>
	 </formalpara>
	</listitem>
       </itemizedlist>

       <para>If your XSLT processors supports custom functions and the
       following functions have been registered, this stylesheet will
       create a 'breadcrumb' style navigation list in the XHTML output.</para>

       <itemizedlist>
        <listitem>
	 <formalpara>
	  <title>asc:breadcrumbs</title>
	  <para>Each time this function is called, it will return the
        next value in the list of breadcrumbs for the current
        path.</para>
	 </formalpara>
	</listitem>
        <listitem>
	 <formalpara>
	  <title>asc:href_from_crumb</title>
	  <para>Each time this function is called, it will return a
        URL for the last value returned by the 'asc:breadcrumbs'
        function.</para>
	 </formalpara>
	</listitem>
       </itemizedlist>

       <para>The namespace for these functions is : 'urn:aaronstraupcope:apache:xbel'</para>       
       </section>

      </partintro>

     </doc:reference>

<!-- ====================================================================== 

     ====================================================================== -->

     <!-- this is considered a bug until I can either
	  a) figure out the correct magic to prevent
	     JavaScript operators from being escaped.
	  b) move the JavaScript into a separate file
	     altogether -->

     <xsl:output method = "html" />
     <xsl:output indent = "yes" />

     <xsl:output doctype-public = "-//W3C//DTD XHTML 1.1//EN" />
     <xsl:output doctype-system = "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" />

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:param name = "disable-output-escaping" />
     <xsl:param name = "base" />
     <xsl:param name = "lang" />

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template match="/">
      <html>

       <xsl:if test = "$lang">
        <xsl:attribute name = "xml:lang">
	 <xsl:value-of select = "$lang" />
	</xsl:attribute>
       </xsl:if>

       <xsl:call-template name = "Head" />
       <xsl:call-template name = "Body" />
      </html>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "Head">
      <head>

       <title>
        <xsl:value-of select = "/xbel/title" />
       </title>

       <meta>
        <xsl:attribute name = "name">author</xsl:attribute>
	<xsl:attribute name = "content">
	 <xsl:value-of select = "/xbel/info/metadata/@owner" />
	</xsl:attribute>
       </meta>
 
       <meta>
        <xsl:attribute name = "name">description</xsl:attribute>
	<xsl:attribute name = "content">
	 <xsl:value-of select = "/xbel/desc" />
	</xsl:attribute>
       </meta>

       <xsl:if test = "$base">
       <base>
        <xsl:attribute name = "href">
	 <xsl:value-of select = "$base" />
	</xsl:attribute>
       </base>
       </xsl:if>

       <xsl:call-template name = "js-code" />
       <xsl:call-template name = "css-code" />

      </head>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "Body">
      <body>

       <xsl:attribute name = "onload">
        <xsl:text>javascript:toggle_display(1);</xsl:text>

        <xsl:if test = "count(/xbel/folder) &lt; 2">
         <xsl:text>javascript:toggle_display('</xsl:text>
	  <xsl:value-of select = "/xbel/folder[1]/@id" />
	 <xsl:text>');</xsl:text>
	</xsl:if>

       </xsl:attribute>

       <xsl:variable name="rpos">
        <xsl:value-of select = "position()" />
       </xsl:variable> 

       <div>

        <xsl:attribute name="class">
	 <xsl:text>root</xsl:text>
	</xsl:attribute>

        <xsl:attribute name="id">
	 <xsl:value-of select="$rpos" />
	</xsl:attribute>

	<div>

         <xsl:attribute name="class">
	  <xsl:text>title</xsl:text>
	 </xsl:attribute>

	 <xsl:attribute name="id">
	  <xsl:text>t</xsl:text>
	  <xsl:value-of select="$rpos" />
	 </xsl:attribute>

         <xsl:if test = "function-available('asc:breadcrumbs')">
          <xsl:call-template name = "Breadcrumbs" />
         </xsl:if>

        </div>

	<xsl:for-each select = "xbel/*">
	 <xsl:call-template name = "TravelFolder">
	  <xsl:with-param name = "pos" select="$rpos" />
	 </xsl:call-template>
	</xsl:for-each>

       </div>

      </body>

     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "Breadcrumbs">
      <div>
       <xsl:attribute name = "class">
        <xsl:text>breadcrumbs</xsl:text>
       </xsl:attribute>
       <ul>
        <xsl:call-template name = "_Breadcrumbs" />
       </ul>
      </div>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "_Breadcrumbs">
      <xsl:variable name = "crumb" select = "asc:breadcrumbs()" />

      <xsl:if test = "$crumb">
       <li>

        <xsl:variable name = "title">
	 <xsl:choose>
	  <xsl:when test = "$crumb = 'root'">
	   <xsl:value-of select = "/xbel/title" />
	  </xsl:when>
	  <xsl:otherwise>
	   <xsl:value-of select = "$crumb" />
	  </xsl:otherwise>
	 </xsl:choose>
	</xsl:variable>

        <xsl:choose>
	 <xsl:when test = "function-available('asc:href_for_crumb')">
         <a>
	  <xsl:attribute name = "href">
	   <xsl:value-of select = "asc:href_for_crumb()" />
	  </xsl:attribute>
	  <xsl:value-of select = "$title" />
	 </a>
	 </xsl:when>
	 <xsl:otherwise>
	  <xsl:value-of select = "$title" />
	 </xsl:otherwise>
	</xsl:choose>
       </li>

       <xsl:call-template name = "_Breadcrumbs" />
      </xsl:if>
      
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "folder">

      <div>

       <xsl:attribute name = "class">
        <xsl:text>folder</xsl:text>
       </xsl:attribute>

       <xsl:attribute name="id">
        <xsl:value-of select = "@id" />
       </xsl:attribute>

        <span>

         <xsl:attribute name = "class">
          <xsl:text>toggle-indicator</xsl:text>
         </xsl:attribute>

	 <xsl:attribute name="id">
	  <xsl:text>t-</xsl:text>
	  <xsl:value-of select="@id" />
	 </xsl:attribute>

         <xsl:attribute name = "onclick">
	  <xsl:text>toggle_display('</xsl:text>
	  <xsl:value-of select="@id" />
	  <xsl:text>')</xsl:text>
	 </xsl:attribute>

	 <xsl:text>&#8595;</xsl:text>
        </span>

        <a>

         <xsl:attribute name = "href">

	  <xsl:for-each select="ancestor::*">
	   <xsl:if test = "(@id)">
	    <xsl:value-of select="./@id" />
	    <xsl:text>/</xsl:text>
	   </xsl:if>
          </xsl:for-each>

          <xsl:value-of select = "@id" />
	  <xsl:text>/</xsl:text>
	 </xsl:attribute>

	 <xsl:call-template name = "_print">
	  <xsl:with-param name = "data">
	   <xsl:value-of select="title" />
	  </xsl:with-param>
	 </xsl:call-template>

	</a>

       <xsl:call-template name="folder-description" />

       <xsl:for-each select = "./*">
        <xsl:call-template name="TravelFolder" />
       </xsl:for-each>

      </div>

     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "bookmark">

      <div>

       <xsl:attribute name="class">
        <xsl:text>bookmark</xsl:text>
       </xsl:attribute>

       <xsl:choose>
        <xsl:when test = "@href">
	 <a>

	  <xsl:attribute name="href">
	   <xsl:value-of select="@href" />
	  </xsl:attribute>

	  <xsl:call-template name = "_print">
	   <xsl:with-param name = "data">
	    <xsl:value-of select = "title" />
	   </xsl:with-param>
	  </xsl:call-template>

         </a>
        </xsl:when>
	<xsl:otherwise>
	 <xsl:call-template name = "_print">
	  <xsl:with-param name = "data">
	   <xsl:value-of select = "title" />
	  </xsl:with-param>
	 </xsl:call-template>
	</xsl:otherwise>
       </xsl:choose>

       <xsl:if test = "./desc">
        <xsl:call-template name = "bookmark-description"/>     
       </xsl:if>

      </div>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "bookmark-description">
      <div>

       <xsl:attribute name = "class">
        <xsl:text>bookmark-description</xsl:text>
       </xsl:attribute>

       <xsl:call-template name = "_print">
        <xsl:with-param name = "data">
	 <xsl:value-of select = "desc" />
	</xsl:with-param>
       </xsl:call-template>

      </div>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "folder-description">
      <div>

       <xsl:attribute name = "class">
        <xsl:text>folder-description</xsl:text>
       </xsl:attribute>

       <xsl:call-template name = "_print">
        <xsl:with-param name = "data">
	 <xsl:value-of select = "desc" />
        </xsl:with-param>
       </xsl:call-template>

      </div>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "separator">
      <div>

       <xsl:attribute name = "class">
        <xsl:text>separator-wrapper</xsl:text>
       </xsl:attribute>

       <div>

        <xsl:attribute name = "class">
         <xsl:text>separator</xsl:text>
        </xsl:attribute>

        <xsl:text>.</xsl:text>

       </div>
      </div>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name="alias">
      <div>

       <xsl:attribute name = "class">
        <xsl:text>alias</xsl:text>
       </xsl:attribute>

       <xsl:text>references *//bookmark[@id='</xsl:text>
       <xsl:value-of select = "@ref" />
       <xsl:text>']</xsl:text>
       &#160;
       <em>
        <xsl:text>XBEL aliases are not supported yet.</xsl:text>
       </em>	  
     </div>
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "TravelFolder">
      <xsl:param name="pos" />

      <xsl:if test = "name()='folder'">
       <xsl:call-template name="folder">
        <xsl:with-param name="pos" select="$pos" />
       </xsl:call-template>
      </xsl:if>

      <xsl:if test = "name()='bookmark'">
       <xsl:call-template name="bookmark"/> 
      </xsl:if>

      <xsl:if test = "name()='separator'">
       <xsl:call-template name="separator"/>
      </xsl:if>

      <xsl:if test = "name()='alias'">
       <xsl:call-template name="alias"/>
      </xsl:if>
  
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <xsl:template name = "_print">
      <xsl:param name = "data" />

      <xsl:choose>
       <xsl:when test = "$disable-output-escaping">
        <xsl:value-of select = "$data" disable-output-escaping = "yes" />
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select = "$data" />
       </xsl:otherwise>
      </xsl:choose>

     </xsl:template>

<!-- ====================================================================== 

     (this will be moved to a separate file in Apache::XBEL.pm 1.4)
     ====================================================================== -->

     <xsl:template name = "js-code">
      <script>

       <xsl:attribute name = "type">
        <xsl:text>text/javascript</xsl:text>
       </xsl:attribute>

       //<![CDATA[

function toggle_display (id) {

    var parent   = document.getElementById(id);
    var children = parent.childNodes.length;

    for (var i = 1; children > i; i++) {
       var child   = parent.childNodes[i];
       var node    = child.nodeName;
       var display = child.style.display;

       if (node == "DIV") {

	  if (display == "block") {
	   child.style.display = "none";  
           set_icon_bgcolor(id,"beige");
           set_icon_text(id,"&#8595;");
	  }

	  else {
	   child.style.display = "block";
           set_icon_bgcolor(id,"#cccccc");
           set_icon_text(id,"&#8593;");
	  }
       }
    }
}

function set_icon_bgcolor (id,colour) { 
    if (document.getElementById("t-"+id)) {
       var icon = document.getElementById("t-"+id).style;
       icon.backgroundColor = colour; 
    }
}

function set_icon_text (id,txt) { 
    if (document.getElementById("t-"+id)) {
       document.getElementById("t-"+id).innerHTML = txt;
    }
}
       //]]>

      </script>
     </xsl:template>

<!-- ====================================================================== 

     (this will be moved to a separate file in Apache::XBEL.pm 1.4)
     ====================================================================== -->

     <xsl:template name = "css-code">
      <style>

       <xsl:attribute name = "type">
        <xsl:text>text/css</xsl:text>
       </xsl:attribute>

       //<![CDATA[

foo {}

body {
     margin-right:0px; 
     margin-left:0px;
     margin-top:0px;

     background:beige;
     font-family:sans-serif;
}

a { 
  color:#666666;
  text-decoration : none;
}

a:hover { 
	text-decoration : none; 
	color:orange; 
}

.wrapper {

}

.breadcrumbs {
}

.breadcrumbs ul {
	     padding:0px;
	     margin:0px;

	     margin-bottom:10px;	     
}

.breadcrumbs ul li {
	     display:inline;
	     font-size:14pt;
	     padding:0px;
	     margin:0px;

	     padding-right:10px;
}

.navbar {
	width : 100%;
	background:beige;
	padding-right:10px;
	padding-left:10px;
	padding-top:5px;
	padding-bottom:5px;
	font-family:sans-serif;
	font-weight:bold;
	font-size:14pt;
}

.navbar .navbar-item {
	padding-right:25px;
}

.navbar .navbar-item a:hover { cursor:w-resize; }

.root { 
      background:#ffffff;
      /* width : 60%;	*/
      font-size:14pt;
      font-weight:bold;
      font-family:sans-serif;
      color:maroon; 
      padding-left:10px;
      padding-top:10px;
      padding-bottom:25px;
      padding-right:10px;
      border:1px dashed darkslategray;
      margin: 10px;
}

.title {
        border-bottom : 1px dashed #ccc;
        margin-bottom:10px;
        }
               
.folder {
	font-size:12pt;
	color:darkslategray;
	padding-left:25px;
	padding-top:5px;
	display:none; 
}

.folder a:hover {
	cursor:e-resize;
}

.alias { 
	  font-weight:normal;
	  font-size:10pt;
	  padding-left:50px;
	  color:#adadad;
	  display:none; 
}

.alias:before {
	      content : "[ ";
}

.alias:after {
	      content : " ]";
}

.bookmark { 
	  font-weight:normal;
	  font-size:10pt;
	  padding-left:50px;
	  color:maroon;
	  display:none; 
}

.bookmark a { 
	  color:maroon; 
          text-decoration:underline;
}

.bookmark a:hover { 
	  color:blue;	  
	  cursor:e-resize;   
}

.bookmark-description {
        color : #666666;
        margin-bottom:10px;
}

.folder-description {
        font-size:12pt;
        color:beige;
}

.separator-wrapper {
        padding-top:5px;padding-bottom:5px;
}

.separator {
        border-top : 3px dashed #ccc;
        font-size  : 1px;
        color      : #ffffff;
}

.toggle-indicator { 
		  font-size:10pt; 
		  background:beige;
		  border:1px solid darkslategray; 
		  width:15px;
		  height:10xpx;
		  clear:right; 
		  text-align:center;
		  padding-right:10px;
		  margin-right:10px;
}

.description {
	     padding-left:10px;
	     color:darkslategray;
}

       //]]>

      </style>  
     </xsl:template>

<!-- ====================================================================== 

     ====================================================================== -->

     <doc:reference>
      <section>
       <title>See also:</title>

       <itemizedlist>
	<listitem>
	 <para>
	  <ulink url = "http://search.cpan.org/dist/Apache-XBEL">Apache::XBEL.pm</ulink>
	 </para>
	</listitem>
       </itemizedlist>

      </section>
     </doc:reference>

<!-- ====================================================================== 
     FIN // $Id: apache-xbel.xsl,v 1.8 2004/03/01 15:11:55 asc Exp $
     ====================================================================== -->

     </xsl:stylesheet>
