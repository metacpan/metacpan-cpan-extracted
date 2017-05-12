<?xml version="1.0"?>
<!-- The control stuff here is actually just a bad reinvention of -->
<!-- XForms... At this point, I think it is too much to change to go -->
<!-- with XForms, but it is certainly desireable for the future. -->

<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ct="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Control"
  xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output"
  xmlns:user="http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output"
  xmlns:cat="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output"
  xmlns:lang="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Language/Output"
  xmlns:i18n="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N"
  xmlns:texts="http://www.kjetil.kjernsmo.net/software/TABOO/NS/I18N/Texts"
  extension-element-prefixes="i18n"
  exclude-result-prefixes="user story cat lang ct i18n texts">


  <xsl:import href="../../transforms/insert-i18n.xsl"/>

 
  <xsl:param name="neg.lang">en</xsl:param>

  <xsl:template name="TinyMCE">
    <script type="text/javascript" src="/jscripts/tiny_mce/tiny_mce.js"></script>
    <script type="text/javascript">
      tinyMCE.init({
        mode : "textareas",
        theme : "advanced",
	plugins : "table,save,emotions,iespell,searchreplace",
	theme_advanced_buttons1 : "save,separator,bold,italic,separator,justifyleft,justifycenter,justifyright,justifyfull,separator,bullist,numlist,separator,formatselect",
	theme_advanced_buttons2 : "cut,copy,paste,separator,undo,redo,separator,search,replace,separator,emotions,separator,link,unlink,image",
	theme_advanced_buttons3 : "tablecontrols,separator,iespell",
	theme_advanced_toolbar_location : "top",
	theme_advanced_toolbar_align : "left",
	theme_advanced_blockformats : "p,h3,h4,h5,h6,div,blockquote",
	convert_fonts_to_spans : true,
	relative_urls : false,
	language : "<xsl:value-of select="$neg.lang"/>",
	verify_html : true,
valid_elements : ""
+"a[accesskey|charset|class|coords|dir&lt;ltr?rtl|href|hreflang|id|lang|name"
  +"|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|rel|rev"
  +"|shape&lt;circle?default?poly?rect|style|tabindex|title|target|type],"
+"abbr[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"acronym[class|dir&lt;ltr?rtl|id|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"address[class|align|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title],"
+"area[accesskey|alt|class|coords|dir&lt;ltr?rtl|href|id|lang|nohref&lt;nohref"
  +"|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup"
  +"|shape&lt;circle?default?poly?rect|style|tabindex|title|target],"
+"bdo[class|dir&lt;ltr?rtl|id|lang|style|title],"
+"big[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"blockquote[dir|style|cite|class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick"
  +"|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout"
  +"|onmouseover|onmouseup|style|title],"
+"br[class|clear&lt;all?left?none?right|id|style|title],"
+"button[accesskey|class|dir&lt;ltr?rtl|disabled&lt;disabled|id|lang|name|onblur"
  +"|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onmousedown"
  +"|onmousemove|onmouseout|onmouseover|onmouseup|style|tabindex|title|type"
  +"|value],"
+"caption[align&lt;bottom?left?right?top|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"cite[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"code[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"col[align&lt;center?char?justify?left?right|char|charoff|class|dir&lt;ltr?rtl|id"
  +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
  +"|onmousemove|onmouseout|onmouseover|onmouseup|span|style|title"
  +"|valign&lt;baseline?bottom?middle?top|width],"
+"colgroup[align&lt;center?char?justify?left?right|char|charoff|class|dir&lt;ltr?rtl"
  +"|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
  +"|onmousemove|onmouseout|onmouseover|onmouseup|span|style|title"
  +"|valign&lt;baseline?bottom?middle?top|width],"
+"dd[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
+"del[cite|class|datetime|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title],"
+"dfn[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"dir[class|compact&lt;compact|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title],"
+"div[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"dl[class|compact&lt;compact|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title],"
+"dt[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
+"em/i[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"fieldset[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"h1[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"h2[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"h3[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"h4[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"h5[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"h6[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"hr[align&lt;center?left?right|class|dir&lt;ltr?rtl|id|lang|noshade&lt;noshade|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|size|style|title|width],"
+"img[align&lt;bottom?left?middle?right?top|alt|border|class|dir&lt;ltr?rtl|height"
  +"|hspace|id|ismap&lt;ismap|lang|longdesc|name|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|src|style|title|usemap|vspace|width],"
+"ins[cite|class|datetime|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title],"
+"kbd[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"li[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title|type"
  +"|value],"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|rel|rev|style|title|target|type],"
+"object[align&lt;bottom?left?middle?right?top|archive|border|class|classid"
  +"|codebase|codetype|data|declare|dir&lt;ltr?rtl|height|hspace|id|lang|name"
  +"|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|standby|style|tabindex|title|type|usemap"
  +"|vspace|width],"
+"ol[class|compact&lt;compact|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|start|style|title|type],"
+"p[align&lt;center?justify?left?right|class|dir&lt;ltr?rtl|id|lang|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|style|title],"
+"param[id|name|type|value|valuetype&lt;DATA?OBJECT?REF],"
+"pre/listing/plaintext/xmp[align|class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick"
  +"|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout"
  +"|onmouseover|onmouseup|style|title|width],"
+"q[cite|class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"s[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
+"samp[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"small[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"span[align|class|class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title],"
+"strike[class|class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title],"
+"strong/b[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"style[dir&lt;ltr?rtl|lang|media|title|type],"
+"sub[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"sup[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title],"
+"table[align&lt;center?left?right|bgcolor|border|cellpadding|cellspacing|class"
  +"|dir&lt;ltr?rtl|frame|height|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|rules"
  +"|style|summary|title|width],"
+"tbody[align&lt;center?char?justify?left?right|char|class|charoff|dir&lt;ltr?rtl|id"
  +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
  +"|onmousemove|onmouseout|onmouseover|onmouseup|style|title"
  +"|valign&lt;baseline?bottom?middle?top],"
+"td[abbr|align&lt;center?char?justify?left?right|axis|bgcolor|char|charoff|class"
  +"|colspan|dir&lt;ltr?rtl|headers|height|id|lang|nowrap&lt;nowrap|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|rowspan|scope&lt;col?colgroup?row?rowgroup"
  +"|style|title|valign&lt;baseline?bottom?middle?top|width],"
+"textarea[accesskey|class|cols|dir&lt;ltr?rtl|disabled&lt;disabled|id|lang|name"
  +"|onblur|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onselect"
  +"|readonly&lt;readonly|rows|style|tabindex|title],"
+"tfoot[align&lt;center?char?justify?left?right|char|charoff|class|dir&lt;ltr?rtl|id"
  +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
  +"|onmousemove|onmouseout|onmouseover|onmouseup|style|title"
  +"|valign&lt;baseline?bottom?middle?top],"
+"th[abbr|align&lt;center?char?justify?left?right|axis|bgcolor|char|charoff|class"
  +"|colspan|dir&lt;ltr?rtl|headers|height|id|lang|nowrap&lt;nowrap|onclick"
  +"|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove"
  +"|onmouseout|onmouseover|onmouseup|rowspan|scope&lt;col?colgroup?row?rowgroup"
  +"|style|title|valign&lt;baseline?bottom?middle?top|width],"
+"thead[align&lt;center?char?justify?left?right|char|charoff|class|dir&lt;ltr?rtl|id"
  +"|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup|onmousedown"
  +"|onmousemove|onmouseout|onmouseover|onmouseup|style|title"
  +"|valign&lt;baseline?bottom?middle?top],"
+"tr[abbr|align&lt;center?char?justify?left?right|bgcolor|char|charoff|class"
  +"|rowspan|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title|valign&lt;baseline?bottom?middle?top],"
+"tt[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
+"u[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress|onkeyup"
  +"|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style|title],"
+"ul[class|compact&lt;compact|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown"
  +"|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover"
  +"|onmouseup|style|title|type],"
+"var[class|dir&lt;ltr?rtl|id|lang|onclick|ondblclick|onkeydown|onkeypress"
  +"|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|style"
  +"|title]"
    });
    </script>
  </xsl:template>

  <xsl:template match="ct:control">
    <xsl:choose>
      <xsl:when test="@type='hidden'">
	<xsl:choose>
	  <xsl:when test="./ct:value/i18n:insert">
	    <input name="{@name}" id="{@name}" type="{@type}" 
		   value="{i18n:include(./ct:value/i18n:insert)}"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <input name="{@name}" id="{@name}" type="{@type}" 
		   value="{./ct:value}"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<div class="control">
	  <label for="{@name}">
	    <xsl:apply-templates select="./ct:title/node()"/>
	  </label>
	  
	  <xsl:if test="./ct:descr">
	    <p class="description">
	      <xsl:apply-templates select="./ct:descr/node()"/>
	    </p>
	  </xsl:if>
	  
	  <xsl:choose>
	    <xsl:when test="@element='input'">
	      <xsl:choose>
		<xsl:when test="@type='checkbox'">
		  <input name="{@name}" id="{@name}" type="checkbox"
			 value="1"> 
		    <xsl:if test="./ct:value='1'">
		      <xsl:attribute name="checked">checked</xsl:attribute>
		    </xsl:if>
		  </input>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:choose>
		    <xsl:when test="./ct:value/i18n:insert">
		      <input name="{@name}" id="{@name}" type="{@type}" 
			     value="{i18n:include(./ct:value/i18n:insert)}">
			<xsl:if test="@size">
			  <xsl:attribute name="size">
			    <xsl:value-of select="@size"/>
			  </xsl:attribute>
			</xsl:if>
			<xsl:if test="@maxlength">
			  <xsl:attribute name="maxlength">
			    <xsl:value-of select="@maxlength"/>
			  </xsl:attribute>
			</xsl:if>
		      </input>
		    </xsl:when>
		    <xsl:otherwise>
		      <input name="{@name}" id="{@name}" type="{@type}" 
			     value="{./ct:value}">
			<xsl:if test="@size">
			  <xsl:attribute name="size">
			    <xsl:value-of select="@size"/>
			  </xsl:attribute>
			</xsl:if>
			<xsl:if test="@maxlength">
			  <xsl:attribute name="maxlength">
			    <xsl:value-of select="@maxlength"/>
			  </xsl:attribute>
			</xsl:if>
		      </input>
		    </xsl:otherwise>
		  </xsl:choose>
		</xsl:otherwise>
	      </xsl:choose>
	    </xsl:when>
	    <xsl:when test="@element='textarea'">
	      <textarea name="{@name}" id="{@name}"
			rows="{@rows}" cols="{@cols}">
		<xsl:choose>
		  <xsl:when test="./ct:value/*/*">
		    <xsl:apply-templates select="./ct:value/*/*" mode="escape-xml"/>		
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:value-of select="./ct:value"/>
		  </xsl:otherwise>
		</xsl:choose>
	      </textarea>
	    </xsl:when>
	    <xsl:when test="@element='select'">
	      <select name="{./@name}" id="{./@name}">
		<xsl:if test="../@type='multiple'">
		  <xsl:attribute name="multiple">multiple</xsl:attribute>
		</xsl:if>
		<xsl:for-each select="./option">
		  <option value="{@value}">
		    <xsl:apply-templates/>
		  </option>
		</xsl:for-each>
		<xsl:for-each select="./ct:value/user:level">
		  <option>
		    <!-- xsl:attribute name="value"><xsl:number
			 from="0"/></xsl:attribute -->
		    <!-- This has to mark as selected both in the case where we have
			 a single parameter found by param:get, but also where there are
			 multiple as found by param:enumerate -->
		    <xsl:if test=".=//user:authlevel">
		      <xsl:attribute name="selected">selected</xsl:attribute>
		    </xsl:if>
		    <xsl:value-of select="."/>
		  </option>
		</xsl:for-each>     
	      </select>
	    </xsl:when>
	    <xsl:when test="./lang:languages">
	      <xsl:apply-templates select="./lang:languages"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:apply-templates select="./cat:categories"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="cat:categories">
    <select name="{../@name}" id="{../@name}">
      <xsl:if test="../@type='multiple'">
	<xsl:attribute name="multiple">multiple</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="./cat:category|cat:primcat"/>
    </select>
  </xsl:template>
  
  <xsl:template match="cat:category|cat:primcat">
    <option value="{cat:catname}">
      <!-- This has to mark as selected both in the case where we have
      a single parameter found by param:get, but also where there are
      multiple as found by param:enumerate -->
      <xsl:if test="../..//ct:value=cat:catname">
	<xsl:attribute name="selected">selected</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="cat:name"/>
    </option>
  </xsl:template>
  
  <xsl:template match="lang:languages">
    <select name="{../@name}" id="{../@name}">
      <xsl:if test="../@type='multiple'">
	<xsl:attribute name="multiple">multiple</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="./lang:language"/>
    </select>
  </xsl:template>
  
  <xsl:template match="lang:language">
    <option value="{lang:code}">
      <!-- This has to mark as selected both in the case where we have
      a single parameter found by param:get, but also where there are
      multiple as found by param:enumerate -->
      <xsl:if test="//ct:value=lang:code">
	<xsl:attribute name="selected">selected</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="lang:localname"/>
    </option>
  </xsl:template>

  <xsl:template name="write-attribute">
    <xsl:text> </xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
  </xsl:template>
  
  
  <xsl:template match="*" mode="escape-xml">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:for-each select="@*">
      <xsl:call-template name="write-attribute"/>
    </xsl:for-each>
    <xsl:text>&gt;</xsl:text>
    <xsl:apply-templates mode="escape-xml"/>
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>&gt;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
