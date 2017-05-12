#
#   Copyright (C) 1998, 1999 Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog.pm,v 1.58 2000/01/27 18:08:37 loic Exp $
#
# 
package Catalog;
use vars qw(@ISA $head %default_templates
	    %datemap
	    $VERSION);
use strict;

use CGI;
use CGI::Carp;
use File::Basename;
use MD5;
use Catalog::implementation;
use Catalog::external;
use Catalog::path qw(path_simplify_component);
use Catalog::tools::sqledit;
use Catalog::tools::tools;

@ISA = qw(Catalog::tools::sqledit Catalog::implementation);

$VERSION = "1.02";
sub Version { $VERSION; }

#
# Yerk. Change to use Locale::Date or something
#
%datemap = (
	     'french' => {
		 'days' => {
		     'Monday' => 'Lundi',
		     'Tuesday' => 'Mardi',
		     'Wednesday' => 'Mercredi',
		     'Thursday' => 'Jeudi',
		     'Friday' => 'Vendredi',
		     'Saturday' => 'Samedi',
		     'Sunday' => 'Dimanche',
		 },
		 'months' => {
		     'January' => 'Janvier',
		     'February' => 'F&eacute;vrier',
		     'March' => 'Mars',
		     'April' => 'Avril',
		     'May' => 'Mai',
		     'June' => 'Juin',
		     'July' => 'Juillet',
		     'August' => 'Ao&ucric;t',
		     'September' => 'Septembre',
		     'October' => 'Octobre',
		     'November' => 'Novembre',
		     'December' => 'Decembre',
		 },
	     },
	     );
$head = "
<body bgcolor=#ffffff>
";

#
# Built in templates
#
%default_templates
    = (
       'error.html' => template_parse('inline error',
"$head
<title>Error message</title>
<H1>Error:</H1>
<PRE>_MESSAGE_</PRE>
"),
       'calpha_root.html' => template_parse('inline calpha_root',
"$head
<title>Alphabetical Navigation</title>

<h3>Alphabetical Navigation</h3>

_A_ _B_ _C_ _D_ _E_ _F_ _G_ _H_ _I_ _J_ _K_ _L_ <p>
_M_ _N_ _O_ _P_ _Q_ _R_ _S_ _T_ _U_ _V_ _W_ _X_ <p>
_Y_ _Z_ _0_ _1_ _2_ _3_ _4_ _5_ _6_ _7_ _8_ _9_ <p>
"),
       'calpha.html' => template_parse('inline calpha',
"$head
<title>Alphabetical Navigation _LETTER_</title>

<h3>Alphabetical Navigation _LETTER_</h3>

<table border=1>
<!-- start entry -->
<tr>_DEFAULTROW_</tr>
<!-- end entry --> 
</table>

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->

"),
       'csetup.html' => template_parse('inline csetup',
"$head
<center>
<h3>The catalog has not been setup</h3>
<p>
Shall I set it up for you ? It will create a table named <b>catalog</b>.
<p>
<form>
<input type=hidden name=context value=csetup_confirm>
<input type=submit value='Yes, setup a catalog'>
</form>

</center>
"),
       'ccontrol_panel.html' => template_parse('inline ccontrol_panel',
qq{$head
<title>Catalog Control Panel</title>

<h3>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Catalog Control Panel</h3>
<p>
<h3><font color=red>_COMMENT_</font></h3>
<p>

<table border=1 cellpadding=6>
<tr><td colspan=9 align=middle><b>Maintain Existing Catalogs</b></td></tr>
<!-- start catalogs -->
<tr>
 <td><b>_NAME_</b></td>
 <td><a href=_SCRIPT_?context=cbrowse&name=_NAME__ID_>browse</a></td>
 <td><a href=_SCRIPT_?context=_COUNT_&name=_NAME_>count</a></td>
 <td><a href=_SCRIPT_?context=cdestroy&name=_NAME_>destroy</a></td>
 <td><a href=_SCRIPT_?context=ccatalog_edit&name=_NAME_>configure</a></td>
 <!-- start theme -->
 <td><a href=_SCRIPT_?context=cedit&name=_NAME__ID_>edit</a></td>
 <td><a href=_SCRIPT_?context=cdump&name=_NAME_>dump</a></td>
 <td><a href=_SCRIPT_?context=cimport&name=_NAME_>load</a></td>
 <td><a href=_SCRIPT_?context=cexport&name=_NAME_>unload</a></td>
 <!-- end theme -->
</tr>
<!-- end catalogs -->
</table>
<p>
<table cellpadding=6><tr><td>
<a href=_SCRIPT_/>Simplified browsing on default catalog</a><br>
<a href=_SCRIPT_?context=cimport>Load catalog from file</a><br>
<a href=_SCRIPT_?context=ccontrol_panel>Redisplay control panel</a><br>
<a href=_SCRIPT_?context=cdemo>Create a demo table (urldemo)</a><br>
</td><td>
<a href=_HTMLPATH_/catalog_toc.html><img src=_HTMLPATH_/images/help.gif alt=Help border=0 align=middle></a>
</td></tr></table>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=cbuild>
Create _NAVIGATION_ catalog on table _TABLES_
<input type=submit value='Create it!'>
</form>
<p>
<table border=1 cellpadding=2>
<tr><td colspan=2 align=middle><b>&nbsp; Configuration Files &nbsp;</b></td></tr>
<tr><td>MySQL</td><td><a href=_SCRIPT_?context=confedit&file=mysql.conf>edit</a></td></tr>
<tr><td>CGI</td><td><a href=_SCRIPT_?context=confedit&file=cgi.conf>edit</a></td></tr>
<tr><td>Catalog</td><td><a href=_SCRIPT_?context=confedit&file=catalog.conf>edit</a></td></tr>
<tr><td>sqledit</td><td><a href=_SCRIPT_?context=confedit&file=sqledit.conf>edit</a></td></tr>
</table>
<p>
<pre></b><i>
<font size=-1>
Catalog-$VERSION <a href=http://www.senga.org/>http://www.senga.org</a>
Copyright 1998, 1999 Loic Dachary

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License , or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, write to the Free Software
    Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
</font>
</i></pre>
}),
       'csearch.html' => template_parse('inline csearch',
"$head
<title>Search results for _TEXT_</title>

<!-- start simple -->
<center>
<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
_WHAT-MENU_
<a href=_SCRIPT_?context=csearch_form&querymode=advanced&_PARAMS_>Advanced Search</a>
<br>
Example: <b>+catalog senga -query</b>
</form>
</center>
<!-- end simple -->

<!-- start advanced -->
<form action=_SCRIPT_ method=POST>
_HIDDEN_
<b>Your search query</b>
<br>
<textarea name=text cols=50 rows=4 wrap>_TEXT-QUOTED_</textarea>
<br>
_WHAT-MENU_
_QUERYMODE-MENU_
<input type=submit value='search'>
<p>
Advanced search syntax examples:
<dl>
<dt> Boolean operators
<dd> <b>catalog and senga and not query or freeware near software</b>
<dt> Precedence
<dd> <b>catalog and ( query or freeware )</b>
<dt> Fields
<dd> <b>comment: ( catalog and query ) or url: edu</b>
</dl>
</form>
<!-- end advanced -->

<!-- start categories -->
<center>Categories matching <b>_TEXT_</b> (_COUNT_)</center>
<ul>
<!-- start entry -->
<li> <a href=_URL_>_PATHNAME_</a>
<!-- end entry -->
</ul>

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
<!-- end categories -->
<!-- start nocategories -->
<center>No category matches the search criterion</center>
<!-- end nocategories -->

<!-- start records -->

<center>Records matching <b>_TEXT_</b> (_COUNT_)</center>

<table border=1>
<!-- start entry -->

<!-- start category -->
<tr><td colspan=20><a href=_URL_>_PATHNAME_</a></td></tr>
<!-- end category -->

<tr>_DEFAULTROW_</tr>
<!-- end entry --> 
</table>

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
<!-- end records -->
<!-- start norecords -->
<center>No record matches the search criterion</center>
<!-- end norecords -->

"),
       'cedit.html' => template_parse('inline cedit',
"$head
<title>Edit category _CATEGORY_</title>

<center><h3><font color=red>_COMMENT_</font></h3></center>

<center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=name value=_NAME_>
<input type=hidden name=context value=csearch>
<input type=hidden name=mode value=_CONTEXT_>
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
<a href=_SCRIPT_?_PARAMS_&mode=cedit&querymode=advanced&context=csearch_form>Advanced Search</a>
</form>
</center>

<h3>Edit category _CATEGORY_</h3> 
<a href='_CENTRYINSERT_'><img src=_HTMLPATH_/images/new.gif alt='Insert a new record and link it to this category' border=0></a>
<a href='_CENTRYSELECT_'><img src=_HTMLPATH_/images/link.gif alt='Link an existing record to this category' border=0></a>
<a href='_CATEGORYINSERT_'><img src=_HTMLPATH_/images/open.gif alt='Create a sub category' border=0></a>
<a href='_CATEGORYSYMLINK_'><img src=_HTMLPATH_/images/plus.gif alt='Create a symbolic link to another category' border=0></a>
<a href='_CONTROLPANEL_'><img src=_HTMLPATH_/images/control.gif alt='Control panel' border=0></a>
<p>
<p>
_PATH_
<p>

<!-- start categories -->
<h3>Sub categories</h3>
<table>
<!-- params 'style' => 'table', 'columns' => 2 -->
<!-- start row --> 
<tr>
<!-- start entry -->
<td> _LINKS_ <a href='_URL_'>_NAME_</a> (_COUNT_) </td>
<!-- end entry -->
</tr>
<!-- end row --> 
</table>
<!-- end categories -->
<p>

<h3>Records in this category</h3>
<!-- start entry -->
<table border=1><tr><td>_LINKS_</td> _DEFAULTROW_</tr></table>
<p>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'catalog_category_select.html' => template_parse('inline catalog_category_select',
"$head
<title>Select category _CATEGORY_</title>

<h3>Select category _CATEGORY_</h3> 
_PATH_
<!-- start symlink -->
<a href='_CATEGORYSYMLINK_'><img src=_HTMLPATH_/images/select.gif alt='Select this category as a symbolic link' border=0></a>
<!-- end symlink -->
<p>

<!-- start categories -->
<h3>Sub categories</h3>
<table>
<!-- params 'style' => 'table', 'columns' => 2 -->
<!-- start row --> 
<tr>
<!-- start entry -->
<td> <a href='_URL_'>_NAME_</a> (_COUNT_) </td>
<!-- end entry -->
</tr>
<!-- end row --> 
</table>
<!-- end categories -->
<p>
"),
       'centryremove_all.html' => template_parse('inline centryremove_all', "$head
<body bgcolor=#ffffff>

<center>

<h3>Confirm removal of record from  _TABLE_</h3>

<form action=_SCRIPT_ method=POST>
<input type=submit name=remove value=remove>
_HIDDEN_
</form>

</center>
"),
       'cbrowse_root.html' => template_parse('inline cbrowse_root',
"$head
<title>Root</title>

<center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=name value=_NAME_>
<input type=hidden name=context value=csearch>
<input type=hidden name=mode value=_CONTEXT_>
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
<a href=_SCRIPT_?_PARAMS_&mode=cbrowse&querymode=advanced&context=csearch_form>Advanced Search</a>
</form>
</center>

<h3>Root</h3>

<!-- start categories -->
<h3>Sub categories</h3>
<ul>
<!-- start entry -->
<li> <a href='_URL_'>_NAME_</a> (_COUNT_)
<!-- end entry -->
</ul>
<!-- end categories -->
<p>
<!-- start entry -->
<p> <table border=1><tr>_DEFAULTROW_<tr></table>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'cbrowse.html' => template_parse('inline cbrowse',
"$head
<title>_CATEGORY_</title>

<center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=name value=_NAME_>
<input type=hidden name=context value=csearch>
<input type=hidden name=mode value=_CONTEXT_>
<input type=text size=40 name=text value='_TEXT-QUOTED_'>
<input type=submit value='search'><br>
<a href=_SCRIPT_?_PARAMS_&mode=cbrowse&querymode=advanced&context=csearch_form>Advanced Search</a>
</form>
</center>

<h3>_CATEGORY_</h3>
<p>
_PATH_
<p>

<!-- start categories -->
<h3>Sub categories</h3>
<ul>
<!-- start entry -->
<li> <a href='_URL_'>_NAME_</a> (_COUNT_)
<!-- end entry -->
</ul>
<!-- end categories -->
<p>
<!-- start entry -->
<p> <table border=1><tr>_DEFAULTROW_<tr></table>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'cdestroy.html' => template_parse('inline cdestroy', "$head
<body bgcolor=#ffffff>

<center>

<h3>Confirm removal of catalog _NAME_</h3>

<form action=_SCRIPT_ method=POST>
<input type=submit name=remove value=remove>
_HIDDEN_
</form>

</center>
"),
       'edit.html' => template_parse('inline catalog edit', "$head
<html>
<body bgcolor=#ffffff>
<title>Edit _FILE_</title>
<center><a href=_SCRIPT_?context=ccontrol_panel>Back to Catalog Control Panel</a></center>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=confedit>
<input type=hidden name=file value=_FILE_>
<input type=hidden name=rows value=_ROWS_>
<input type=hidden name=cols value=_COLS_>
<textarea name=text cols=_COLS_ rows=_ROWS_>_TEXT_</textarea>
<p>
<center>
<input type=submit name=action value=save>
<input type=submit name=action value=refresh>
</center>
<p>
_COMMENT_
</form>
</html>
"),
       'cdate_default.html' => template_parse('inline catalog cdate_default', "$head
<html>
<body bgcolor=#ffffff>
<title>Date catalog</title>
<!-- start years -->
  <a href=_YEARLINK_>_YEARFORMATED_</a> (_COUNT_)

  <blockquote>
  <!-- start months -->
    <!-- params format => '%M' -->
    <a href=_MONTHLINK_>_MONTHFORMATED_</a> (_COUNT_)

    <ul>
    <!-- start days -->
      <!-- params format => '%W, %d' -->
      <li> <a href=_DAYLINK_>_DAYFORMATED_</a> (_COUNT_)
    <!-- end days -->
    </ul>

  <!-- end months -->
  </blockquote>

<!-- end years -->

<!-- start records -->
Records
<!-- start entry -->
<p> <table border=1><tr>_DEFAULTROW_<tr></table>
<!-- end entry -->

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->

<!-- end records -->
</html>
"),
       'catalog_category_insert.html' => template_parse('inline catalog_category_insert', "$head
<title>Create a sub category</title>

<h3>Create a sub category</h3>
<form action=_SCRIPT_ method=POST>
_HIDDEN_
<table>
<tr><td><b>Category name*</b></td><td><input type=text name=name></td></tr>
</table>
<input type=submit value='Create it!'>
</form>
"),
       'catalog_category_edit.html' => template_parse('inline catalog_category_edit', "$head
<title>Edit category _NAME_</title>

<h3>Edit category _NAME_</h3>
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Category name*</b></td><td><input type=text name=name value='_NAME-QUOTED_'></td></tr>
<tr><td><b>Total records</b></td><td>_COUNT_</td></tr>
<tr><td><b>Rowid</b></td><td>_ROWID_</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'catalog_theme_insert.html' => template_parse('inline catalog_theme_insert', "$head
<title>Create _NAVIGATION_ catalog on table _TABLENAME_</title>

<h3>Create _NAVIGATION_ catalog on table _TABLENAME_</h3>

<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=hidden name=tablename value=_TABLENAME_>
<input type=hidden name=navigation value=_NAVIGATION_>
<table>
<tr><td><b>Catalog name*</b></td><td><input type=text name=name></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60></td></tr>
<tr><td><b>Dump path</b></td><td><input type=text name=dump size=60></td></tr>
<tr><td><b>Dump location</b></td><td><input type=text name=dumplocation size=60></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
</table>
<input type=submit value='Create it!'>

</form>
"),
       'catalog_theme_edit.html' => template_parse('inline catalog_theme_edit', "$head
<title>Edit _NAVIGATION_ catalog _NAME_</title>
<h3>Edit _NAVIGATION_ catalog _NAME_</h3>

_EDITCOMMENT_
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Table name</b></td><td>_TABLENAME_</td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60 value='_CORDER-QUOTED_'></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60 value='_CWHERE-QUOTED_'></td></tr>
<tr><td><b>Dump path</b></td><td><input type=text name=dump size=60 value='_DUMP-QUOTED_'></td></tr>
<tr><td><b>Dump location</b></td><td><input type=text name=dumplocation size=60 value='_DUMPLOCATION-QUOTED_'></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'catalog_alpha_insert.html' => template_parse('inline catalog_alpha_insert', "$head
<title>Create _NAVIGATION_ catalog on table _TABLENAME_</title>

<h3>Create _NAVIGATION_ catalog on table _TABLENAME_</h3>

<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=hidden name=tablename value=_TABLENAME_>
<input type=hidden name=navigation value=_NAVIGATION_>
<table>
<tr><td><b>Catalog name*</b></td><td><input type=text name=name></td></tr>
<tr><td><b>Field name*</b></td><td><input type=text name=fieldname></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
</table>
<input type=submit value='Create it!'>

</form>
"),
       'catalog_alpha_edit.html' => template_parse('inline catalog_alpha_edit', "$head
<title>Edit _NAVIGATION_ catalog _NAME_</title>
<h3>Edit _NAVIGATION_ catalog _NAME_</h3>

_EDITCOMMENT_
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Table name</b></td><td>_TABLENAME_</td></tr>
<tr><td><b>Field name</b></td><td><input type=text name=fieldname value='_FIELDNAME_'></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60 value='_CORDER-QUOTED_'></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60 value='_CWHERE-QUOTED_'></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
<tr><td><b>Last cache update</b></td><td><input type=text name=updated value='_UPDATED_'</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'catalog_date_insert.html' => template_parse('inline catalog_date_insert', "$head
<title>Create _NAVIGATION_ catalog on table _TABLENAME_</title>

<h3>Create _NAVIGATION_ catalog on table _TABLENAME_</h3>

<form action=_SCRIPT_ method=POST>
_HIDDEN_
<input type=hidden name=tablename value=_TABLENAME_>
<input type=hidden name=navigation value=_NAVIGATION_>
<table>
<tr><td><b>Catalog name*</b></td><td><input type=text name=name></td></tr>
<tr><td><b>Field name*</b></td><td><input type=text name=fieldname></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
</table>
<input type=submit value='Create it!'>

</form>
"),
       'catalog_date_edit.html' => template_parse('inline catalog_date_edit', "$head
<title>Edit _NAVIGATION_ catalog _NAME_</title>
<h3>Edit _NAVIGATION_ catalog _NAME_</h3>

_EDITCOMMENT_
<form action=_SCRIPT_ method=POST>
<input type=submit name=update value=update>
_HIDDEN_
<table>
<tr><td><b>Table name</b></td><td>_TABLENAME_</td></tr>
<tr><td><b>Field name</b></td><td><input type=text name=fieldname value='_FIELDNAME_'></td></tr>
<tr><td><b>ORDER BY</b></td><td><input type=text name=corder size=60 value='_CORDER-QUOTED_'></td></tr>
<tr><td><b>WHERE</b></td><td><input type=text name=cwhere size=60 value='_CWHERE-QUOTED_'></td></tr>
<tr><td><b>Options</b></td><td>_INFO-CHECKBOX_</td></tr>
<tr><td><b>Last cache update</b></td><td><input type=text name=updated value='_UPDATED_'</td></tr>
<tr><td><b>Created</b></td><td>_CREATED_</td></tr>
<tr><td><b>Last modified</b></td><td>_MODIFIED_</td></tr>
</table>
</form>
"),
       'cdump.html' => template_parse('inline cdump', "$head
<title>Dump _NAME_ catalog in HTML</title>

<h3>Dump _NAME_ catalog in HTML</h3>

<center><h3><font color=red>Warning! All files and subdirectories of the specified path will first be removed.</font></h3></center>
<form action=_SCRIPT_ method=POST>
_HIDDEN_
<table>
<tr><td><b>Full path name*</b></td><td><input type=text name=path size=50 value='_PATH_'></td></tr>
<tr><td><b>Location*</b></td><td><input type=text name=location size=50 value='_LOCATION_'></td></tr>
</table>
<input type=submit value='Dump it!'>

</form>
"),
       'cimport.html' => template_parse('inline cimport', "$head
<title>Load a thematic catalog</title>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=cimport_confirm>
<table>
<tr><td><b>Catalog name</b></td><td><input type=text name=name value=_NAME_></td></tr>
<tr><td><b>File path</b></td><td><input type=text name=file></td></tr>
</table>
<input type=submit value='Load it!'>
</form>
"),
       'cexport.html' => template_parse('inline cexport', "$head
<title>Unload a thematic catalog</title>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=cexport_confirm>
<input type=hidden name=name value=_NAME_>
<table>
<tr><td><b>Catalog name</b></td><td>_NAME_</td></tr>
<tr><td><b>File path</b></td><td><input type=text name=file></td></tr>
</table>
<input type=submit value='Unload it!'>
</form>
"),
       );


#
# Class specific initialization (called by new)
#
sub initialize {
    my($self) = @_;

    $self->Catalog::tools::sqledit::initialize();
    $self->Catalog::implementation::initialize();

    my($config) = config_load("catalog.conf");
    %$self = (%$self, %$config) if(defined($config));

    my($encoding) = $self->{'encoding'} || "ISO-8859-1";
    $self->{'encoding'} = $encoding;
    
    push(@{$self->{'params'}}, 'name', 'path');
    my($templates) = $self->{'templates'};
    %$templates = ( %$templates, %default_templates );
}


#
# Called after catalog edited/removed/created
#
sub cinfo_clear {
    my($self) = @_;

    delete($self->{'ccatalog'});
}

#
# HTML catalog setup step 1
#
sub csetup {
    my($self) = @_;

    my($template) = $self->template("csetup");
    return $self->stemplate_build($template);
}

#
# HTML catalog setup step 2
#
sub csetup_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    $self->csetup_api();

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => 'The catalog has been setup'
    }));
}

#
# HTML display control panel
#
sub ccontrol_panel {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();
    
    my($url) = $cgi->script_name();

    if(!defined($self->{'csetup'})) {
	return $self->csetup();
    }

    my($template) = $self->template("ccontrol_panel");

    my($template_catalogs) = $template->{'children'}->{'catalogs'};
    $self->cerror("missing catalogs part") if(!defined($template_catalogs));
    my($template_theme) = $template_catalogs->{'children'}->{'theme'};

    if($ccatalog) {
	my($html) = '';
	my(%navigation2function) = (
				    'alpha' => 'calpha_count',
				    'theme' => 'category_count',
				    'date' => 'cdate_count',
				    );
	my($assoc) = $template_catalogs->{'assoc'};
	my($name, $catalog);
	while(($name, $catalog) = each(%$ccatalog)) {
	    my($root) = $catalog->{'root'};
	    my($navigation) = $catalog->{'navigation'};
	    my($count) =  $navigation2function{$navigation};
	    my($id) = '';
	    if($navigation eq 'theme') {
		$id = "&id=$root";
		my($assoc) = $template_theme->{'assoc'};
		template_set($assoc, '_ID_', $id);
		template_set($assoc, '_COUNT_', $count);
		template_set($assoc, '_NAME_', $name);
		template_set($assoc, '_SCRIPT_', $url);
	    } else {
		$template_theme->{'skip'} = 1;
	    }
	    template_set($assoc, '_ID_', $id);
	    template_set($assoc, '_COUNT_', $count);
	    template_set($assoc, '_NAME_', $name);
	    $html .= $self->stemplate_build($template_catalogs);
	}

	$template_catalogs->{'html'} = $html;
    } else {
	$template_catalogs->{'skip'} = 'yes';
    }
    my($navigation) = $cgi->popup_menu(-name => 'navigation',
				       -values => ['theme', 'alpha', 'date'],
				       -default => 'theme',
				       -labels => {
					   'theme' => 'Thematical',
					   'alpha' => 'Alphabetical',
					   'date' => 'Chronological',
					   });
    template_set($template->{'assoc'}, '_NAVIGATION_', $navigation);
    my($tables) = $cgi->popup_menu(-name => 'table',
				   -values => $self->{'ctables'});
    template_set($template->{'assoc'}, '_TABLES_', $tables);
    template_set($template->{'assoc'}, '_COMMENT_', $cgi->param('comment'));
    return $self->stemplate_build($template);
}

#
# HTML import XML representation step 1
#
sub cimport {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($template) = $self->template("cimport");
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_NAME_', $cgi->param('name'));
    template_set($assoc, '_PATH_', $cgi->param('path'));
    template_set($assoc, '_COMMENT_', $cgi->param('comment'));
    
    return $self->stemplate_build($template);
}

#
# HTML import XML representation step 2
#
sub cimport_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    my($file) = $cgi->param('file');

    $self->cerror("no file specified") if(!defined($file));
    $self->cerror("$file is not a readable file") if(! -r $file);

    eval {
	$self->cimport_api($name, $file);
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->cerror("load failed, check logs");
    }

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => "The $name catalog was (re)loaded"
    }));
}

#
# HTML export XML representation step 1
#
sub cexport {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($template) = $self->template("cexport");
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_NAME_', $cgi->param('name'));
    
    return $self->stemplate_build($template);
}

#
# HTML export XML representation step 2
#
sub cexport_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    my($file) = $cgi->param('file');

    $self->cerror("no file specified") if(!defined($file));
    my($dir) = dirname($file);
    $self->cerror("directory $dir is not writable") if(! -w $dir);

    eval {
	$self->cexport_api($name, $file);
    };
    
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->cerror("load failed, check logs");
    }

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => "The $name catalog was unloaded"
    }));
}

#
# HTML create demo data table
#
sub cdemo {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    $self->cdemo_api();

    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

#
# HTML Create a symbolic link to a category
# param rowid not set : navigate catalog structure
# param rowid set : create symlink to rowid
#
sub categorysymlink {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Show a form to create a new category symlink
    #
    my($rowid) = $cgi->param('rowid');
    my($name) = $cgi->param('name');
    my($root) = $ccatalog->{$name}->{'root'};
    if(!defined($rowid)) {
	my($params) = $self->params('context' => 'cedit',
				    'path' => undef,
				    'style' => 'catalog_category_select',
				    'id' => $root);
	eval {
	    $cgi = $cgi->fct_call($params,
				  'name' => 'select',
				  'args' => { },
				  'returned' => { },
				  );
	};
	if($@) {
	    my($error) = $@;
	    print STDERR $error;
	    $self->cerror("recursive cgi call failed, check logs");
	}
	return $self->cedit($cgi);
    } else {
	my($name) = $cgi->param('name');
	$cgi = $cgi->fct_return('context' => 'cedit');
	my($id) = $cgi->param('id');
	$self->categorysymlink_api($name, $id, $rowid);
	return $self->cedit($cgi);
    }
}

#
# HTML destroy a catalog step 1
#
sub cdestroy {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    $self->cinfo();

    my($template) = $self->template('cdestroy');
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_NAME_', $cgi->param('name'));
    template_set($assoc, '_HIDDEN_', $self->hidden('context' => 'cdestroy_confirm'));

    return $self->stemplate_build($template);
}

#
# HTML destroy a catalog step 2
#
sub cdestroy_confirm {
    my($self, $cgi) = @_;

    my($name) = $cgi->param('name');
    $self->cerror("no catalog name specified") if(!defined($name));

    $self->cdestroy_api($name);

    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

#
# HTML display a category for editing
#
sub cedit {
    my($self, $cgi) = @_;

    my(%info) = ('mode' => 'cedit');

    return $self->cedit_1($cgi, \%info);
}

#
# HTML display a category specified by the pathname param only
# Map the pathname to id with catalog_path table.
#
sub pathcontext {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();
    my($pathname) = $cgi->param('pathname');
    my($params) = $self->{'pathcontext_params'};
    $cgi->reset_params($params);
    $cgi->param('page_length' => 1000000);
    my($name) = $cgi->param('name');
    $self->pathcheck($name);
    if(!defined($cgi->param('name'))) {
	$self->cerror("missing name from pathcontext_params in catalog.conf");
    }
    if(!exists($ccatalog->{$name})) {
	$self->cerror("the default catalog name, $name (from pathcontext_params in catalog.conf) is
not an existing catalog");
    }
    my($catalog) = $ccatalog->{$name};
    if($catalog->{'navigation'} ne 'theme') {
	$self->cerror("pathcontext only valid for theme catalog");
    }

    $cgi->param('context', 'cbrowse');
    $cgi->param('pathname', $pathname);
    my(%info) = ('mode' => 'cbrowse');
    return $self->cedit_1($cgi, \%info);
}

#
# HTML display a catalog (date,alpha,theme)
#
sub cbrowse {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($catalog) = $ccatalog->{$cgi->param('name')};

    if($catalog->{'navigation'} eq 'alpha') {
	return $self->calpha($cgi);
    } elsif($catalog->{'navigation'} eq 'date') {
	return $self->cdate($cgi);
    } else {
	my(%info) = ('mode' => 'cbrowse');
	return $self->cedit_1($cgi, \%info);
    } 

}

#
# HTML display an alpha catalog
#
sub calpha {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($letter) = $cgi->param('letter');
    if(!defined($letter)) {
	my($base) = "calpha_root";
	my($template) = $self->template($base);
	my($assoc) = $template->{'assoc'};

	my($day) = 24 * 60 * 60;
	if(($catalog->{'updated'} || 0) < time() - $day) {
	    $self->calpha_count_1_api($name);
	}
	my($rows) = $self->db()->exec_select("select letter,count from catalog_alpha_$name");
	$rows = { map { $_->{'letter'} => $_->{'count'} } @$rows };
	my($url) = $self->ccall();
	my($tag);
	foreach $tag (keys(%$assoc)) {
	    my($what);
	    ($letter, $what) = $tag =~ /_(.)(URL|COUNT|LETTER)_/;
	    ($letter) = $tag =~ /_(.)_/ if(!defined($what));
	    if(defined($letter)) {
		$letter = lc($letter);
		if(exists($rows->{$letter})) {
		    if(defined($what) && $what eq 'URL') {
			$assoc->{$tag} = $self->ccall('letter' => ($rows->{$letter} > 0 ? $letter : 'none'));
		    } elsif(defined($what) && $what eq 'COUNT') {
			$assoc->{$tag} = $rows->{$letter};
		    } elsif(defined($what) && $what eq 'LETTER') {
			$assoc->{$tag} = $rows->{$letter} > 0 ? $letter : "${letter}0";
		    } else {
			my($count) = $rows->{$letter};
			my($html);
			if($count > 0) {
			    $html = "<a href='$url&letter=$letter'>$letter</a> ($count)";
			} else {
			    $html = $letter;
			}
			$assoc->{$tag} = $html;
		    }
		} else {
		    $assoc->{$tag} = '';
		}
	    }
	}
	
	return $self->stemplate_build($template);
    } else {
	$self->cerror("no entries for this letter in $name") if($letter eq 'none');
	return $self->catalog_searcher("calpha", $catalog->{'tablename'}, { 'mode' => 'cbrowse'}, " $catalog->{'fieldname'} like '$letter\%' ", "letter");
	
    }
}

#
# HTML force recalculation of the cached data for alpha catalog
#
sub calpha_count {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');

    #
    # Force recalculation at first browsing action
    #
    $self->calpha_count_api($name);

    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

#
# HTML display a date catalog
#
sub cdate {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};

    my(%intervals) = $self->cdate_cgi2intervals($cgi);

    my($day) = 24 * 60 * 60;
    if((($catalog->{'updated'} || 0) < time() - $day) ||
       ($self->db()->exec_select_one("select count(*) as count from catalog_date_$name")->{'count'} <= 0)) {
	$self->cdate_count_1_api($name);
    }

    #
    # Try to load the most specific template first, then backup to
    # cdate_default if none is found.
    #
    my($prefix) = $cgi->param('template') ? "cdate_" . $cgi->param('template') : "cdate_default";
    my($template) = template_load("$prefix.html", $self->{'templates'}, $cgi->param('style'));
    if(!defined($template)) {
	$template = $self->template("cdate_default");
    }

    #
    # Format the index
    #
    if(exists($template->{'children'}->{'years'})) {
	$self->cdate_index($template->{'children'}->{'years'}, $intervals{'index'},
			   {
			       'complement' => '0101',
			       'length' => 4,
			       'format' => '%Y',
			       'order' => 'tag desc',
			       'tag_ftag' => 'YEARFORMATED',
			       'tag_link' => 'YEARLINK',
			       'tag_date' => 'YEARDATE',
			       'next_period' => 'months',
			       },
			   {
			       'complement' => '01',
			       'length' => 6,
			       'format' => '%M %Y',
			       'order' => 'tag desc',
			       'tag_ftag' => 'MONTHFORMATED',
			       'tag_link' => 'MONTHLINK',
			       'tag_date' => 'MONTHDATE',
			       'next_period' => 'days',
			       },
			   {
			       'complement' => '',
			       'length' => 8,
			       'format' => '%d %M %Y',
			       'tag_ftag' => 'DAYFORMATED',
			       'tag_link' => 'DAYLINK',
			       'tag_date' => 'DAYDATE',
			       'order' => 'tag desc',
			       });
    }

    #
    # Format the record list
    #
    if(exists($template->{'children'}->{'records'})) {
	$self->cdate_records($template->{'children'}->{'records'}, $intervals{'records'});
    }
    
    return $self->stemplate_build($template);
}

#
# HTML display a data catalog calendar
#
sub cdate_index {
    my($self, $template, $interval, $spec, @specs) = @_;

#    warn("from = $interval->{'from'} => to = $interval->{'to'}");
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    my($url) = $cgi->script_name();

#    warn("cdate_index " . ostring($interval));

    $self->cdate_normalize($interval);

    my($length) = $spec->{'length'};
    my($format) = exists($template->{'params'}->{'format'}) ? $template->{'params'}->{'format'} : $spec->{'format'};
    my($order) = exists($template->{'params'}->{'order'}) ? $template->{'params'}->{'order'} : $spec->{'order'};
    my($language) = $template->{'params'}->{'language'};
#    warn($language);
    my($from) = substr($interval->{'from'}, 0, $length);
    my($to) = substr($interval->{'to'}, 0, $length);

    #
    # Recurse if template specified by user
    #
    my($next_period) = $spec->{'next_period'};
    if(defined($next_period) &&
       !exists($template->{'children'}->{$next_period})) {
	undef($next_period);
    }
    
    my($sql) = "select tag,date_format(concat(tag, '$spec->{'complement'}'), '$format') as ftag,count from catalog_date_$name where length(tag) = $length and tag $interval->{'from_op'} '$from' and tag $interval->{'to_op'} '$to' order by $order";
    my($rows) = $self->db()->exec_select($sql);
#    warn($sql);

    my($assoc) = $template->{'assoc'};

    my($html) = '';
    my($row);
    foreach $row (@$rows) {
	my($ftag) = $row->{'ftag'};
	if($language) {
	    $ftag =~ s/(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)/$datemap{$language}{'days'}{$1}/g;
	    $ftag =~ s/(January|February|March|April|May|June|July|August|September|October|November|December)/$datemap{$language}{'months'}{$1}/g;
	}
	template_set($assoc, "_$spec->{'tag_ftag'}_", $ftag);
	template_set($assoc, "_$spec->{'tag_date'}_", $row->{'tag'});
	template_set($assoc, "_$spec->{'tag_link'}_", $self->ccall('date' => $row->{'tag'}));
	template_set($assoc, "_COUNT_", $row->{'count'});

	if(defined($next_period)) {
	    my($interval_new) = $self->cdate_intersection($self->cdate_normalize({ 'date' => $row->{'tag'} }), $interval);
	    $self->cdate_index($template->{'children'}->{$next_period},
			       $interval_new,
			       @specs);
	}

	$html .= $self->stemplate_build($template);
    }

    $template->{'html'} = $html;
}

#
# HTML display a date catalog list of records
#
sub cdate_records {
    my($self, $template, $interval) = @_;
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    my($url) = $cgi->script_name();

    my($from) = $interval->{'from'};
    $from =~ s/^(\d\d\d\d)(\d\d)(\d\d)$/$1-$2-$3 00:00:00/;
    my($to) = $interval->{'to'};
    $to =~ s/^(\d\d\d\d)(\d\d)(\d\d)$/$1-$2-$3 23:59:59/;

    my($field) = $catalog->{'fieldname'};
    my($table) = $catalog->{'tablename'};
    my($where) = " ( $table.$field $interval->{'from_op'} '$from' and $table.$field $interval->{'to_op'} '$to' ) ";
    
    if(defined($catalog->{'cwhere'}) && $catalog->{'cwhere'} !~ /^\s*$/) {
	$where .= " and ($catalog->{'cwhere'})";
    }

#    warn($where);

    my(%context) = (
		    'context' => 'catalog entries',
		    'params' => [ 'from', 'to', 'date', 'index_from', 'index_to', 'index_date', 'records_from', 'records_to', 'records_date', 'template' ],
		    'url' => $cgi->script_name(),
		    'page' => scalar($cgi->param('page')),
		    'page_length' => scalar($cgi->param('page_length')),
		    'template' => $template,
		    'expand' => 'yes',
		    'table' => $table,
		    'where' => $where,
		    'order' => $catalog->{'corder'},
		    );

    return $self->searcher(\%context);
}

#
# HTML translate date cgi argument to interval structure
#
sub cdate_cgi2intervals {
    my($self, $cgi) = @_;

    my(%params) = (
		   'all' => {
		       'date' => scalar($cgi->param('date')),
		       'from' => scalar($cgi->param('from')),
		       'to' => scalar($cgi->param('to')),
		   },
		   'index' => {
		       'date' => scalar($cgi->param('index_date')),
		       'from' => scalar($cgi->param('index_from')),
		       'to' => scalar($cgi->param('index_to')),
		   },
		   'records' => {
		       'date' => scalar($cgi->param('records_date')),
		       'from' => scalar($cgi->param('records_from')),
		       'to' => scalar($cgi->param('records_to')),
		   },
		   );

    my(@params);
    if($cgi->param('date') ||
       $cgi->param('from') ||
       $cgi->param('to')) {
	push(@params, 'all');
    } else {
	push(@params, 'index', 'records');
    }

    #
    # Normalize arguments
    #
    my($param);
    foreach $param (@params) {
	$self->cdate_normalize($params{$param});
    }
    
    #
    # Expand so that index and records are filled
    #
    if($params[0] eq 'all') {
	$params{'index'} = $params{'records'} = $params{'all'};
    }

    return (
	     'index' => $params{'index'},
	     'records' => $params{'records'} );
}

#
# HTML force recalculation of the cached data for date catalog
#
sub cdate_count {
    return calpha_count(@_);
}

#
# HTML recalculate counts for each category
#
sub category_count {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    $self->category_count_api($name);
    return $self->ccontrol_panel(Catalog::tools::cgi->new({'context' => 'ccontrol_panel'}));
}

#
# HTML search categories and records (SQL style)
#
sub csearch {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($navigation) = $catalog->{'navigation'};

    $self->cerror("%s catalog cannot be searched", $navigation) if($navigation ne 'theme');

    my($what) = $cgi->param('what');
    my($mode) = $cgi->param('mode') || 'cbrowse';

    if($mode eq 'static') {
	$mode = 'pathcontext';
	$ENV{'SCRIPT_NAME'} = $catalog->{'dumplocation'};
    }
    
    my($template) = $self->template('csearch');

    my($select_category);
    $select_category = $self->csearch_param2select('categories') if(!defined($what) || $what eq 'categories' || $what eq '');
#    warn($select_category);
    my($select_records);
    $select_records = $self->csearch_param2select('records') if(!defined($what) || $what eq 'records' || $what eq '');
#    warn($select_records);

    my($results_count) = 0;
    #
    # Search in categories
    #
    my($template_categories) = $template->{'children'}->{'categories'};
    $self->cerror("missing categories part") if(!defined($template_categories));
    my($template_nocategories) = $template->{'children'}->{'nocategories'};
    $self->cerror("missing nocategories part") if(!defined($template_nocategories));
    if(defined($select_category)) {
	my($layout) = sub {
	    my($template, $subname, $result, $context) = @_;

	    my($assoc) = $template->{'assoc'};
	    my($row) = $result->{"catalog_category_$name"};
	    my(@result_key) = keys(%$row);
#	    warn("result_key = @result_key, $row->{'pathname'}");
	    
	    #
	    # Build forged tags
	    #
	    if(exists($assoc->{'_URL_'})) {
		my($url);
		if($mode eq 'pathcontext') {
		    my($pathname) = $row->{'pathname'};
		    $url = $cgi->script_name() . $pathname;
		} else {
		    my($path) = $row->{'path'};
		    $path =~ s/^,(.*),$/$1/o;
		    $url = $self->ccall('context' => $mode,
					'id' => $row->{'rowid'},
					'path' => $path);
		}
		$assoc->{'_URL_'} = $url;
	    }

	    $result->{"catalog_path_$name"} = {
		'pathname' => $row->{'pathname'},
	    };
	    
	    $self->searcher_layout_result($template, $subname, $result, $context);
	};
	my(%context) = (
			'params' => [ 'text', 'what', 'mode', 'querymode' ],
			'url' => $cgi->script_name(),
			'page' => scalar($cgi->param('page')),
			'page_length' => scalar($cgi->param('page_length')),
			'context' => 'catalog search categories',
			'template' => $template_categories,
			'accept_empty' => 'yes',
			'layout' => $layout,
			'table' => "catalog_category_$name",
			'sql' => $select_category,
			);

	eval {
	    $results_count = $self->searcher(\%context);
	};
	if($@) {
	    my($error) = $@;
	    $self->cerror("The query failed, check the syntax");
	}

	if($results_count <= 0) {
	    $template_categories->{'skip'} = 1;
	    #
	    # If searching in records, do not bark because nothing found,
	    # wait for records search to complete.
	    #
	    if(defined($select_records)) {
		$template_nocategories->{'skip'} = 1;
	    }
	} else {
	    $template_nocategories->{'skip'} = 1;
	    my($assoc) = $template_categories->{'assoc'};
	    template_set($assoc, '_COUNT_', $results_count);
	    template_set($assoc, '_TEXT_', $cgi->param('text'));
	    template_set($assoc, '_TEXT-QUOTED_', Catalog::tools::cgi::myescapeHTML($cgi->param('text')));
	}
    } else {
	$template_categories->{'skip'} = 1;
	$template_nocategories->{'skip'} = 1;
    }
    #
    # Search in records, if no category found
    #
    my($template_records) = $template->{'children'}->{'records'};
    $self->cerror("missing records part") if(!defined($template_records));
    my($template_norecords) = $template->{'children'}->{'norecords'};
    $self->cerror("missing norecords part") if(!defined($template_norecords));
    if($results_count <= 0 && defined($select_records)) {
	my($catalog) = $self->cinfo()->{$name};
	my($table) = $catalog->{'tablename'};
	my($current_pathname) = '';
	
	my($layout) = sub {
	    my($template, $subname, $result, $context) = @_;

	    my($assoc) = $template->{'assoc'};
	    my($row) = $result->{$table};
	    my(@result_key) = keys(%$row);
#	    warn("result_key = @result_key, $row->{'pathname'}");
	    
	    my($template_category) = $template->{'children'}->{'category'};
	    $self->cerror("missing records/category part") if(!defined($template_category));
	    if($row->{'pathname'} ne $current_pathname) {
		$current_pathname = $row->{'pathname'};
		my($assoc) = $template_category->{'assoc'};
		#
		# Build forged tags
		#
		if(exists($assoc->{'_URL_'})) {
		    my($url);
		    if($mode eq 'pathcontext') {
			my($pathname) = $row->{'pathname'};
			$url = $cgi->script_name() . $pathname;
		    } else {
			my($path) = $row->{'path'};
			$path =~ s/^,(.*),$/$1/o;
			$url = $self->ccall('context' => $mode,
					    'id' => $row->{'id'},
					    'path' => $path);
		    }
		    $assoc->{'_URL_'} = $url;
		}

		$self->row2assoc("catalog_path_$name", $row, $assoc);
		$template_category->{'skip'} = 0;
	    } else {
		$template_category->{'skip'} = 1;
	    }
	    
	    $self->searcher_layout_result($template, $subname, $result, $context);
	};
	my(%context) = (
			'params' => [ 'text', 'what', 'mode', 'querymode' ],
			'url' => $cgi->script_name(),
			'page' => scalar($cgi->param('page')),
			'page_length' => scalar($cgi->param('page_length')),
			'context' => 'catalog search records',
			'template' => $template_records,
			'accept_empty' => 'yes',
			'layout' => $layout,
			'table' => $table,
			'sql' => $select_records,
			);

	eval {
	    $results_count = $self->searcher(\%context);
	};
	if($@) {
	    my($error) = $@;
	    $self->cerror("The query failed, check the syntax");
	}

	if($results_count <= 0) {
	    $template_records->{'skip'} = 1;
	} else {
	    $template_norecords->{'skip'} = 1;
	    my($assoc) = $template_records->{'assoc'};
	    template_set($assoc, '_COUNT_', $results_count);
	    template_set($assoc, '_TEXT_', $cgi->param('text'));
	    template_set($assoc, '_TEXT-QUOTED_', Catalog::tools::cgi::myescapeHTML($cgi->param('text')));

	}
    } else {
	$template_records->{'skip'} = 1;
	$template_norecords->{'skip'} = 1;
    }

    $self->csearch_fill_form($cgi, $template, $results_count);

    my($assoc) = $template->{'assoc'};
    template_set($assoc, '_COUNT_', $results_count);
    template_set($assoc, '_TEXT_', $cgi->param('text'));
    template_set($assoc, '_TEXT-QUOTED_', Catalog::tools::cgi::myescapeHTML($cgi->param('text')));

    return $self->stemplate_build($template);
}

sub csearch_form {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($navigation) = $catalog->{'navigation'};

    $self->cerror("%s catalog cannot be searched", $navigation) if($navigation ne 'theme');

    my($template) = $self->template('csearch');

    $template->{'children'}->{'records'}->{'skip'} = 1;
    $template->{'children'}->{'norecords'}->{'skip'} = 1;
    $template->{'children'}->{'categories'}->{'skip'} = 1;
    $template->{'children'}->{'nocategories'}->{'skip'} = 1;

    $self->csearch_fill_form($cgi, $template, 0);

    return $self->stemplate_build($template);
}

sub csearch_fill_form {
    my($self, $cgi, $template, $results_count) = @_;

    my($what) = $cgi->param('what');

    my($what_menu) = $cgi->popup_menu(-name => 'what',
				      -values => ['', 'categories', 'records'],
				      -default => '',
				      -labels => {
					  '' => 'Category Names and Records',
					  'categories' => 'Category Names only',
					  'records' => 'Records only',
				      });
    my($querymode_menu) = $cgi->popup_menu(-name => 'querymode',
					   -values => ['simple', 'advanced'],
					   -default => 'simple',
					   -labels => {
					       'simple' => 'Simple Syntax',
					       'advanced' => 'Advanced Syntax',
					   });
    my($querymode) = $cgi->param('querymode') || 'simple';
    my($notquerymode) = $querymode eq 'simple' ? 'advanced' : 'simple';
    my(%has_template) = (
			 'simple' => exists($template->{'children'}->{'simple'}),
			 'advanced' => exists($template->{'children'}->{'advanced'})
			 );
    my($template_form) = $has_template{$querymode} ? $template->{'children'}->{$querymode} : $template;
    $template->{'children'}->{$notquerymode}->{'skip'} = 1 if($has_template{$notquerymode});

    my($url) = $cgi->script_name();
    
    my($assoc) = $template_form->{'assoc'};
    template_set($assoc, '_HIDDEN_',
		 $self->hidden('mode' => scalar($cgi->param('mode')),
			       'context' => 'csearch'));
    template_set($assoc, '_PARAMS_',
		 $self->params('mode' => scalar($cgi->param('mode')),
			       'context' => undef));
    template_set($assoc, '_SCRIPT_', $url);
    template_set($assoc, '_WHAT_', $what);
    template_set($assoc, '_WHAT-MENU_', $what_menu);
    template_set($assoc, '_QUERYMODE_', $querymode);
    template_set($assoc, '_QUERYMODE-MENU_', $querymode_menu);
    template_set($assoc, '_COUNT_', $results_count);
    template_set($assoc, '_TEXT_', $cgi->param('text'));
    template_set($assoc, '_TEXT-QUOTED_', Catalog::tools::cgi::myescapeHTML($cgi->param('text')));
}

#
# HTML translate cgi parameters to select order for search
#
sub csearch_param2select {
    my($self, $what) = @_;
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($words) = $cgi->param('text');
    my($querymode) = $cgi->param('querymode');
    #
    # No search if nothing specified
    #
    return undef if(!defined($words) && $words =~ /^\s*$/o);

    if($what eq 'categories') {
	return $self->csearch_param2select_categories($name, $words, $querymode);
    } else {
	return $self->csearch_param2select_records($name, $words, $querymode);
    }
}

#
# HTML translate cgi parameters to select order for searching records
#
sub csearch_param2select_records {
    my($self, $name, $words, $querymode) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($table) = $catalog->{'tablename'};
    my($table_info) = $self->db()->info_table($table);
    my($primary_key) = $table_info->{'_primary_'};
    my($spec) = $self->{'search'}->{$name};

    my($fields);
    if(defined($spec) && exists($spec->{'searched'})) {
	$fields = $spec->{'searched'};
	$self->cerror("no searched fields specified in catalog.conf") if(!$fields);
    } else {
	my(@fields);
	my($field, $info);
	while(($field, $info) = each(%$table_info)) {
	    push(@fields, $field) if(ref($info) eq 'HASH' && $info->{'type'} eq 'char');
	}
	$self->cerror("no char fields in $table") if(!@fields);
	$fields = join(',', @fields);
    }

    my($fields_extracted) = '';
    if(defined($spec) && exists($spec->{'extracted'})) {
	$fields_extracted = $spec->{'extracted'};
    } else {
	$fields_extracted = "$table.*";
    }
    $self->cerror("no extracted fields for $table") if($fields_extracted =~ /^\s*$/);

    my($order) = '';
    if(defined($spec) && exists($spec->{'order'})) {
	$order = ", $spec->{'order'}";
    }

    my($select) = "select $fields_extracted,c.pathname,c.path,c.id from $table, catalog_entry2category_$name as b, catalog_path_$name as c where __WHERE__ and $table.$primary_key = b.row and b.category = c.id order by c.pathname asc $order";

    my($result);
    eval {
	( $result ) = $self->csearch_parse($words, $querymode, $fields, $select);
    };
    if($@) {
	warn("$@");
	$self->cerror("The syntax of the <b>$words</b> query is incorrect");
    }

    return $result;
}

#
# HTML translate cgi parameters to select order for searching categories
#
sub csearch_param2select_categories {
    my($self, $name, $words, $querymode) = @_;

    my($select) = "select a.rowid,a.name,a.info,b.path,b.pathname from catalog_category_$name as a,catalog_path_$name as b where a.rowid = b.id and __WHERE__ ";

    my($result);
    eval {
	( $result ) = $self->csearch_parse($words, $querymode, 'a.name', $select);
    };
    if($@) {
	warn("$@");
	$self->cerror("The syntax of the <b>$words</b> query is incorrect");
    }

    return $result;
}

#
# HTML dump theme catalog in file tree step 1
#
sub cdump {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name};
    my($navigation) = $catalog->{'navigation'};
    $self->cerror("%s catalog cannot be dumped", $navigation) if($navigation ne 'theme');

    my($template) = $self->template('cdump');
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_PATH_', Catalog::tools::cgi::myescapeHTML($catalog->{'dump'}));
    template_set($assoc, '_LOCATION_', Catalog::tools::cgi::myescapeHTML($catalog->{'dumplocation'}));
    template_set($assoc, '_NAME_', $name);
    template_set($assoc, '_HIDDEN_', $self->hidden('context' => 'cdump_confirm'));

    return $self->stemplate_build($template);
}

#
# HTML dump theme catalog in file tree step 2
#
sub cdump_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($path) = $cgi->param('path');
    $self->cerror("you must specify a path") if(!$path);
    my($location) = $cgi->param('location');
    $self->cerror("you must specify a location") if(!$location);
    my($name) = $cgi->param('name');

    my($script) = $ENV{'SCRIPT_NAME'};
    $ENV{'SCRIPT_NAME'} = $location;

    $self->cdump_api($name, $path, sub { $self->cdump_category_layout(@_) });
    
    if(defined($script)) {
	$ENV{'SCRIPT_NAME'} = $script;
    } else {
	delete($ENV{'SCRIPT_NAME'});
    }

    $self->db()->update("catalog", "name = '$name'",
			'dump' => $path,
			'dumplocation' => $location);

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => 'The catalog has been dumped'
    }));
}

#
# HTML dump theme catalog layout of a category
#
sub cdump_category_layout {
    my($self, $pathname) = @_;

    $self->gauge();
    return $self->pathcontext(Catalog::tools::cgi->new({
	'context' => 'pathcontext',
	'pathname' => $pathname,
    }));
}

#
# HTML display category for editing or browsing (subroutine)
#
sub cedit_1 {
    my($self, $cgi, $info) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    my($name) = $cgi->param('name');
    my($catalog) = $ccatalog->{$name}
	    || $self->cerror("Can't edit unknown catalog '%s'", $name);
    my($navigation) = $catalog->{'navigation'};
    $self->cerror("A %s catalog cannot be edited", $navigation) if($navigation ne 'theme');
    $self->pathcheck($name);
    my($opath) = $self->cgi2path();
    my($id);
    eval { $id = $opath->id(); };
    $self->cerror("The category path was not found") if(!defined($id));

    my($category) = $self->db()->exec_select_one("select * from catalog_category_$name where rowid = $id");

    #
    # Load template
    #
    my($base) = $info->{'mode'};
    if(defined($category->{'info'}) && $category->{'info'} =~ /\broot\b/ && $base eq 'cbrowse') {
	$base .= "_root";
    }
    my($template) = $self->template($base);
    my($assoc) = $template->{'assoc'};

    #
    # Set top level tags
    #
    #
    # Comment
    #
    template_set($assoc, '_COMMENT_', $cgi->param('comment'));
    #
    # Path substitution
    #
    $opath->ptemplate_set($template);
    #
    # Hidden parameters
    #
    template_set($assoc, '_HIDDEN_', $self->hidden('path' => undef,
						   'context' => undef));
    template_set($assoc, '_PARAMS_', $self->params('path' => undef,
						   'context' => undef));
    #
    # Category name
    #
    template_set($assoc, '_CATEGORY_', $category->{'name'});
    template_set($assoc, '_CATEGORY-CODED_', CGI::escape($category->{'name'}));
    #
    # Catalog name
    #
    template_set($assoc, '_NAME_', $name);
    #
    # Current category id
    #
    template_set($assoc, '_CATEGORYID_', $id);
    #
    # Context
    #
    template_set($assoc, '_CONTEXT_',
	$opath->fashion() eq 'intuitive' ? 'pathcontext' : $cgi->param('context'));

    if($info->{'mode'} eq 'cedit') {
	template_set($assoc, '_CONTROLPANEL_', $self->ccall('context' => 'ccontrol_panel',
							    'id' => undef,
							    'name' => undef,
							    'path' => undef));
	my($context);
	foreach $context ('centryinsert', 'centryselect', 'categoryinsert', 'categorysymlink') {
	    my($call) = $self->ccall('context' => $context, 'id' => $id);
	    template_set($assoc, "_" . uc($context) . "_", $call);
	}
	#
	# Symbolic link selection 
	#
	if(exists($template->{'children'}->{'symlink'})) {
	    my($template) = $template->{'children'}->{'symlink'};
	    if(defined($cgi->fct_name()) && $cgi->fct_name() eq 'select') {
		my($assoc) = $template->{'assoc'};
		my($call) = $self->ccall('context' => 'categorysymlink',
					 'rowid' => $id);
		template_set($assoc, "_HTMLPATH_", $self->{'htmlpath'});
		template_set($assoc, "_CATEGORYSYMLINK_", $call);
	    } else {
		$template->{'skip'} = 1;
	    }
	}
    }

    #
    # Show entries
    #
    if(exists($template->{'children'}->{'entry'}) ||
       exists($template->{'children'}->{'row'})) {
	my($table) = $self->cinfo()->{$name}->{'tablename'};
	my($row_ids) = $self->select_entry_rows($name, $id); # can subclass to filter
	if(@$row_ids) {
	    $self->cedit_searcher($template, $table, $info, join(',', @$row_ids));
	} else {
	    $template->{'children'}->{'entry'}->{'skip'} = 1;
	    $template->{'children'}->{'row'}->{'skip'} = 1;
	    $template->{'children'}->{'pager'}->{'skip'} = 1;
	}
    }

    #
    # Show sub categories
    #
    $self->category_searcher($template->{'children'}->{'categories'}, $id, $info, $category);

    return $self->stemplate_build($template);
}

#
# HTML display sub-categories of a category for editing/display
#
sub category_searcher {
    my($self, $template, $id, $info, $current_category, $recursion) = @_;
    my($cgi) = $self->{'cgi'};

    #
    # Define search domain
    #
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    my($category) = "catalog_category_$name";
    my($path) = "catalog_path_$name";
    my($category2category) = "catalog_category2category_$name";

    template_set($template->{'assoc'}, '_CATEGORY_', $current_category->{'name'});
    template_set($template->{'assoc'}, '_CATEGORY-CODED_', CGI::escape($current_category->{'name'}));

    my($where) = '';
    if(defined($catalog->{'info'}) &&
       $catalog->{'info'} =~ /hideempty/ && $info->{'mode'} ne 'cedit') {
	$where = " and a.count > 0 ";
    }

    #
    # Only display categories explicitely marked to be displayed
    #
    $where .= " and find_in_set('displaygrandchild',a.info)"
	if($recursion);

    my($sql) = qq{
	select a.rowid, a.name, a.count, b.info, c.pathname
	from $category as a, $category2category as b, $path as c
	where a.rowid = b.down and b.down = c.id and b.up = $id 
		$where
	order by a.name
    };
    my($layout);
    $layout = sub {
	my($template, $name, $result, $context) = @_;

	my($assoc) = $template->{'assoc'};
	my($row) = $result->{$category};
	my($issymlink) = defined($row->{'info'}) && $row->{'info'} =~ /symlink/;

        if(exists $template->{'children'}{'categories'}) {
	    my($subid) = $result->{$category}{'rowid'};
	    my($cur_category) = $self->db()->exec_select_one("select * from $category where rowid = $subid");

	    my $count = $self->category_searcher($template->{'children'}{'categories'}, $subid, $info, $cur_category, 'recursion');
	    if($count) {
		$template->{'children'}{'categories'}{'skip'} = 0
	    }
	}

	#
	# Build forged tags
	#
	if(exists($assoc->{'_URL_'})) {
	    my($url);
	    if($cgi->param('pathname')) {
		my($pathname) = $row->{'pathname'};
		$url = $cgi->script_name() . $pathname;
	    } else {
		my($path) = $cgi->param('path');
		$url = $self->ccall('context' => $info->{'mode'},
				    'id' => $row->{'rowid'},
				    'path' => join(',', ($path || ()), $row->{'rowid'}));
	    }
	    $assoc->{'_URL_'} = $url;
	}
	#
	# Fix field values
	#
	if($cgi->param('pathname') && $issymlink) {
	    $row->{'count'} = '@';
	}

	$self->searcher_layout_result($template, $name, $result, $context);
    };

    my(%context) = (
		    'context' => 'catalog categories',
		    'template' => $template,
		    'layout' => $layout,
		    'table' => $category,
		    'sql' => $sql,
		    );

    return $self->searcher(\%context);
}

#
# HTML display records of a category for editing/display
#
sub cedit_searcher {
    my($self, $template, $table, $info, $primary_values) = @_;

    my($info_table) = $self->db()->info_table($table);
    my($primary_key) = $info_table->{'_primary_'};

    my($where) = "$table.$primary_key in ($primary_values)";

    return $self->catalog_searcher($template, $table, $info, $where, 'id');
}

#
# HTML display records for editing/display
# Common function for date/alpha/theme catalogs
#
sub catalog_searcher {
    my($self, $template, $table, $info, $where, $param) = @_;
    my($cgi) = $self->{'cgi'};

    my($info_table) = $self->db()->info_table($table);
    my($primary_key) = $info_table->{'_primary_'};

    #
    # Define search domain
    #
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    $where = '' if(!defined($where));
    if(defined($catalog->{'cwhere'}) && $catalog->{'cwhere'} !~ /^\s*$/) {
	$where .= " and ($catalog->{'cwhere'})";
    }

    my(%context) = (
		    'context' => 'catalog entries',
		    'params' => [ $param ],
		    'url' => $cgi->script_name(),
		    'page' => scalar($cgi->param('page')),
		    'page_length' => scalar($cgi->param('page_length')),
		    'template' => $template,
		    'expand' => 'yes',
		    'table' => $table,
		    'where' => $where,
		    'order' => $catalog->{'corder'},
		    );

    return $self->searcher(\%context);
}

#
# HTML callback of sqledit function searcher : add links to actions
# depending on the context of the search.
#
sub searcher_links {
    my($self, $table, $row, $context) = @_;

    my($imagespath) = "$self->{'htmlpath'}/images";
    my($cgi) = $self->{'cgi'};
    my($name) = $cgi->param('name');
    my($url) = $cgi->script_name();
    if($context->{'context'} eq 'catalog categories') {
	my($id) = $cgi->param('id');
	my($issymlink);
	my(@symlink);
	if($row->{'info'} && $row->{'info'} =~ /\bsymlink\b/) {
	    $issymlink = 1;
	    @symlink = (
			'symlink' => 'yes',
			);
	}
	my($html) = '';
	$html .= "<a href=\"" . $self->ccall('context' => 'categoryremove',
					     'id' => $id,
					     'path' => undef,
					     @symlink,
					     'child' => $row->{'rowid'}) . "\"><img src=$imagespath/cut.gif alt='Remove this category' border=0></a> ";
	if(!$issymlink) {
	    $html .= "<a href=\"" . $self->ccall('context' => 'categoryedit',
						 'child' => $row->{'rowid'},
						 'id' => $id) . "\"><img src=$imagespath/edit.gif alt='Edit category properties' border=0></a> ";
	}
	return $html;
    } elsif($context->{'context'} eq 'catalog entries') {
	my($info) = $self->db()->info_table($table);
	my($primary_key) = $info->{'_primary_'};
	my($id) = $cgi->param('id');
	my($html);
	my(%spec) = (
		     'centryremove' => ['Unlink from this category', 'unlink'],
		     'centryremove_all' => ['Unlink from all categories and remove record', 'cut'],
		     );
	my($tag, $label);
	foreach $tag (sort(keys(%spec))) {
	    my($label, $image) = @{$spec{$tag}};
	    $html .= "<a href=\"" . $self->ccall('row' => $row->{$primary_key},
						 'context' => $tag,
						 'id' => $id) . "\"><img src=$imagespath/$image.gif alt='$label' border=0></a> ";
	}
	$html .= "<a href=\"" . $self->ccall('row' => $row->{$primary_key},
					     'context' => 'centryedit',
					     'id' => $id) . "\"><img src=$imagespath/edit.gif alt='Edit the record' border=0></a> ";
	return $html;
    } else {
	return $self->Catalog::tools::sqledit::searcher_links($table, $row, $context);
    }
}

#sub crowid2categories {
#    my($self, $name, $rowid, $url) = @_;
#
#    my($category2entry) = "catalog_entry2category_$name";
#    my($category) = "catalog_category_$name";
#    my($rows) = $self->db()->exec_select("select a.rowid,a.name from $category as a,$category2entry as b where b.row = $rowid and b.category = a.rowid");
#    my(@categories);
#    my($row);
#    foreach $row (@$rows) {
#	push(@categories, "<a href=$url&id=$row->{'rowid'}>$row->{'name'}</a>");
#    }
#    return (@categories ? \@categories : undef);
#}

#
# HTML walk records of a theme catalog, call $func on each record
#
sub walk {
    my($self, $func, @ids) = @_;
    
    my($cgi) = $self->{'cgi'};

    my($name) = $cgi->param('name');

    $self->walk_api($name, $func, @ids);
}

#
# HTML fill template with specified categories
#
sub category_display {
    my($self, $template, $ids) = @_;
    my($cgi) = $self->{'cgi'};

    my($name) = $cgi->param('name');
    my($category) = "catalog_category_$name";

    my($sql);
    if(defined($ids)) {
	my($limit) = join(',', @$ids);
	$sql = "select a.rowid,a.name,a.count from $category as a where a.rowid in ($limit)";
    } else {
	my($catalog) = $self->cinfo()->{$name};
	my($id) = $catalog->{'root'};
	my($category2category) = "catalog_category2category_$name";
	$sql = "select a.rowid,a.name,a.count,b.info from $category as a, $category2category as b where a.rowid = b.down and b.up = $id";
    }

    my(%context) = (
		    'context' => 'catalog categories display',
		    'template' => $template,
		    'table' => $category,
		    'sql' => $sql,
		    );

    return $self->searcher(\%context);
}

#sub category_rows {
#    my($self, $template, $rows, $info) = @_;
#
#    if(@$rows <= 0) {
#	$template->{'skip'} = 1;
#	return;
#    }
#    
#    my($html) = '';
#    my($params) = $template->{'params'};
#    if(!exists($params->{'style'}) || $params->{'style'} eq 'list') {
#	my($template_entry) = $template->{'children'}->{'entry'};
#
#	my($row);
#	foreach $row (@$rows) {
#	    $html .= $self->category_row($template_entry, $row, $info);
#	}
#	$template_entry->{'html'} = $html;
#    } elsif($params->{'style'} eq 'table') {
#	my($template_row) = $template->{'children'}->{'row'};
#	my($template_entry) = $template_row->{'children'}->{'entry'};
#	my($count_max) = $params->{'columns'} || 5;
#	my($count) = 0;
#	my($columns) = '';
#	my($row);
#	foreach $row (@$rows) {
#	    if($count >= $count_max) {
#		$template_entry->{'html'} = $columns;
#		$html .= $self->stemplate_build($template_row);
#		$columns = '';
#		$count = 0;
#	    }
#	    $count++;
#	    $columns .= $self->category_row($template_entry, $row, $info);
#	}
#	if($count > 0) {
#	    $template_entry->{'html'} = $columns;
#	    $html .= $self->stemplate_build($template_row);
#	}
#	$template_row->{'html'} = $html;
#    } else {
#	croak("unknown style $params->{'style'}");
#    }
#}
#
#sub category_row {
#    my($self, $template, $row, $info) = @_;
#    my($cgi) = $self->{'cgi'};
#
#    my($assoc) = $template->{'assoc'};
#    template_set($assoc, '_NAME_', $row->{'name'});
#    template_set($assoc, '_ROWID_', $row->{'rowid'});
#    if(exists($assoc->{'_URL_'})) {
#	my($path) = $cgi->param('path');
#	my($url) = $self->ccall('context' => $info->{'mode'},
#				'id' => $row->{'rowid'},
#				'path' => join(',', ($path || ()), $row->{'rowid'}));
#	$assoc->{'_URL_'} = $url;
#    }
#    if(defined($row->{'info'}) && $row->{'info'} =~ /symlink/) {
#	template_set($assoc, '_COUNT_', '@');
#    } else {
#	template_set($assoc, '_COUNT_', $row->{'count'});
#    }
#
#    return $self->stemplate_build($template);
#}

#
# HTML remove an empty category
#
sub categoryremove {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    my($id) = $cgi->param('child');
    my($parent) = $cgi->param('id');
    my($symlink) = $cgi->param('symlink');

    $self->categoryremove_api($name, $parent, $id, $symlink);

    $cgi->param('context', 'cedit');
    return $self->cedit($cgi);
}

#
# HTML Create a subcategory
# param rowid not set : ask for category name
# param rowid set : create the category
#
sub categoryinsert {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    #
    # Show a form to create a new category
    #
    if(!defined($cgi->param('rowid'))) {
	my($name) = $cgi->param('name');
	$self->pathcheck($name);
	my($table) = "catalog_category_$name";
	my($params) = $self->params('context' => 'insert_form',
				    'style' => 'catalog_category',
				    'table' => $table,
				    'name' => undef);
	eval {
	    $cgi = $cgi->fct_call($params,
				  'name' => 'insert',
				  'args' => { },
				  'returned' => {
				      'fields' => 'rowid',
				      'context' => 'categoryinsert',
				  });
	};
	if($@) {
	    my($error) = $@;
	    print STDERR $error;
	    $self->cerror("recursive cgi call failed, check logs");
	}
	return $self->insert_form($cgi);
    } else {
	my($name) = $cgi->param('name');
	#
	# Link the created category to its parent
	#
	my($up_id) = $cgi->param('id');
	my($down_id) = $cgi->param('rowid');
	$self->categoryinsert_api($name, $up_id, $down_id);
	$cgi->param('context', 'cedit');
	return $self->cedit($cgi);
    }
    
}

#
# HTML edit the category record
#
sub categoryedit {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    #
    # Editing form
    #
    my($child) = $cgi->param('child');
    my($table) = "catalog_category_" . $cgi->param('name');
    my($params) = $self->params('context' => 'edit',
				'style' => 'catalog_category',
				'table' => $table,
				'primary' => $child,
				'name' => undef);
    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'edit',
			      'args' => { },
			      'returned' => {
				  'context' => 'categoryedit_done',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->cerror("recursive cgi call failed, check logs");
    }
    return $self->edit($cgi);
}

#
# HTML the category record has been edited, update catalog structure
# accordingly.
#
sub categoryedit_done {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    $self->pathcheck($name);
    my($child) = $cgi->param('child');

    $self->categoryedit_api($name, $child);

    $cgi->param('context' => 'cedit');
    $self->cedit($cgi);
}

#
# HTML edit a catalog entry
#
sub centryedit {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Editing form
    #
    my($name) = $cgi->param('name');
    my($table) = $ccatalog->{$name}->{'tablename'};
    my($params) = $self->params('context' => 'edit',
				'primary' => $cgi->param('row'),
				'table' => $table,
				'name' => undef);
    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'edit',
			      'args' => { },
			      'returned' => {
				  'context' => 'cedit',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->cerror("recursive cgi call failed, check logs");
    }
    return $self->edit($cgi);
}

#
# HTML search the record table for a record to insert in current
# category.
#
sub centryselect {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();
    
    my($name) = $cgi->param('name');
    my($table) = $ccatalog->{$name}->{'tablename'};
    
    my($params) = $self->params('context' => 'search_form',
				'table' => $table,
				'name' => undef);

    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'select',
			      'args' => { },
			      'returned' => {
				  'fields' => 'rowid',
				  'context' => 'centryinsert',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->cerror("recursive cgi call failed, check logs");
    }
    return $self->search_form($cgi);
}

#
# HTML remove catalog entry and all links to categories step 1
#
sub centryremove_all {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($table) = $cgi->param('table');

    my($template) = $self->template("centryremove_all");

    template_set($template->{'assoc'}, '_HIDDEN_',
		 $self->hidden('id' => $cgi->param('id'),
			       'row' => $cgi->param('row'),
			       'context' => 'centryremove_all_confirm'));
    
    return $self->stemplate_build($template);
}

#
# HTML remove catalog entry and all links to categories step 2
#
sub centryremove_all_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    #
    # Remove all the links between the entry and the categories
    #
    my($primary_value) = $cgi->param('row');

    $self->centryremove_all_api($name, $primary_value);

    $cgi->param('context', 'cedit');
    return $self->cedit($cgi);
}

#
# HTML remove link between current category and record
#
sub centryremove {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($name) = $cgi->param('name');
    #
    # Remove the link between the entry and the category
    #
    my($id) = $cgi->param('id');
    my($row) = $cgi->param('row');

    $self->centryremove_api($name, $id, $row);

    $cgi->param('context', 'cedit');
    return $self->cedit($cgi);
}

#
# HTML Create a record and link to current category
# param rowid not set : insert form for the record
# param rowid set : link new record to current category
#
sub centryinsert {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Show a form to create a new entry
    #
    my($name) = $cgi->param('name');
    my($table) = $ccatalog->{$name}->{'tablename'};
    if(!defined($cgi->param('rowid'))) {
	my($params) = $self->params('context' => 'insert_form',
				    'table' => $table,
				    'name' => undef);
	eval {
	    $cgi = $cgi->fct_call($params,
				  'name' => 'insert',
				  'args' => { },
				  'returned' => {
				      'fields' => 'rowid',
				      'context' => 'centryinsert',
				  });
	};
	if($@) {
	    my($error) = $@;
	    print STDERR $error;
	    $self->cerror("recursive cgi call failed, check logs");
	}
	return $self->insert_form($cgi);
    } else {
	my($name) = $cgi->param('name');
	#
	# Link the created entry to its category
	#
	my($id) = $cgi->param('id');
	my($rowid) = $cgi->param('rowid');

	$self->centryinsert_api($name, $id, $rowid);

	$cgi->param('context', 'cedit');
	return $self->cedit($cgi);
    }
}

#
# HTML Create a new catalog (date/alpha/theme)
# param rowid not set : fill the category description record
# param rowid set : call the appropriate catalog creation function
#
sub cbuild {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($error);
    my($navigation) = $cgi->param('navigation');
    my($table) = $cgi->param('table');
    #
    # Show a form to create a new catalog
    #
    if(!defined($cgi->param('rowid'))) {
	$error = $self->cbuild_check('', $table, $navigation, 'step1');
	if(!defined($error)) {
	    my($style) = "catalog_$navigation";
	    my($params) = $self->params('context' => 'insert_form',
					'table' => 'catalog',
					'navigation' => $navigation,
					'style' => $style,
					'tablename' => $table,
					'name' => undef);
	    eval {
		$cgi = $cgi->fct_call($params,
				      'name' => 'insert',
				      'args' => { },
				      'returned' => {
					  'fields' => 'rowid,name,tablename,fieldname,navigation',
					  'context' => 'cbuild',
				      });
	    };
	    if($@) {
		my($error) = $@;
		print STDERR $error;
		$self->cerror("recursive cgi call failed, check logs");
	    }
	    return $self->insert_form($cgi);
	}
    } else {
	my($rowid) = $cgi->param('rowid');
	my($name) = $cgi->param('name');
	my($field)= $cgi->param('fieldname');
	$error = $self->cbuild_check($name, $table, $navigation, 'step2', $field);

	if(!defined($error)) {
	    $self->cbuild_real($rowid, $name, $table, $navigation, $field);
	} else {
	    $self->db()->exec("delete from catalog where rowid = $rowid");
	}
    }
    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
	'comment' => $error,
	'table' => $table,
	'navigation' => $navigation,
    }));
}

#
# HTML edit catalog description record
#
sub ccatalog_edit {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($ccatalog) = $self->cinfo();

    #
    # Edit the informations about the catalog
    #
    my($name) = $cgi->param('name');
    my($rowid) = $ccatalog->{$name}->{'rowid'};
    my($navigation) = $ccatalog->{$name}->{'navigation'};
    my($params) = $self->params('context' => 'edit',
				'table' => 'catalog',
				'style' => "catalog_$navigation",
				'primary' => $rowid);
    eval {
	$cgi = $cgi->fct_call($params,
			      'name' => 'edit',
			      'args' => { },
			      'returned' => {
				  'context' => 'ccatalog_edit_done',
			      });
    };
    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->cerror("recursive cgi call failed, check logs");
    }
    return $self->edit($cgi);
}

#
# HTML update catalog structure after modification of catalog record
#
sub ccatalog_edit_done {
    my($self, $cgi) = @_;

    $self->cinfo_clear();

    return $self->ccontrol_panel(Catalog::tools::cgi->new({
	'context' => 'ccontrol_panel',
    }));
}

#
# HTML Return a Catalog::path object built with the cgi params
#
sub cgi2path {
    my($self) = @_;
    my($cgi) = $self->{'cgi'};

    my($path) = $cgi->param('path');
    my($id) = $cgi->param('id');
    my($pathname) = $cgi->param('pathname');
    my($url);
    my($fashion);
    if(defined($pathname)) {
	$url = $cgi->script_name();
	$fashion = 'intuitive';
    } else {
	$url = $self->ccall(path => undef, id => undef);
	$fashion = 'cgi';
    }
    my($name) = $cgi->param('name');
    my($catalog) = $self->cinfo()->{$name};
    my($root) = $catalog->{'root'};

    my($path_obj);

    eval {
	$path_obj = Catalog::path->new(
				       'db' => $self->db(),
				       'root' => $root,
				       'name' => $name,
				       'url' => $url,
				       'id' => $id,
				       'path' => $path,
				       'pathname' => $pathname,
				       'fashion' => $fashion,
				       'path_root_label' => $self->{'path_root_label'},
				       'path_separator' => $self->{'path_separator'},
				       'path_constant' => $self->{'path_constant'},
				       'path_last_link' => $self->{'path_last_link'},
				       );
    };
    $self->cerror("The category path was not found") if(!defined($path_obj));

    return $path_obj;
}

#
# When generating sqledit recursive calls, strip catalog name and path
#
sub call {
    my($self, $table, $info, $row, %pairs) = @_;

    my($tag);
    foreach $tag ('name', 'path') {
	$pairs{$tag} = undef if(!defined($pairs{$tag}));
    }

    return $self->Catalog::tools::sqledit::call($table, $info, $row, %pairs);
}

#
# Generate cgi call that preserves persistent parameters
#
sub ccall {
    my($self, %pairs) = @_;

    my($params) = $self->params(%pairs);
    my($script) = $self->{'cgi'}->script_name();
    return "$script?$params";
}

#
# Change error handling method for Catalog::implementation base class
#
sub cerror {
    my($self) = shift;
    $self->serror(@_);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
