package CGI::OptimalQuery::InteractiveQuery;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';

sub new {
  my $pack = shift;
  my $o = $pack->SUPER::new(@_);

  $$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowWidth} ||= 800;
  $$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowHeight} ||= 600;

  return $o;
}




sub get_defaultCSS {
return <<TILEND;

#OQinfo tr td { border: 1px solid #efefef; }
#OQinfo tr td.OQinfoName { border: 1px solid #666666; }

#OQdataLHead { 
  background-color: #efefef; 
}

td.OQinfoName {
  width: 1%;
  font-size: 13px;
}

.OQinfoVal {
  background-color: white !important;
  font-size: 13px;
}

#OQtitle {
  width: 40%;
  padding-left: 10px !important;
}

#OQhead td {
  padding: 4px !important;
}

/* workaround: too bad 'text-align: center' does not work */
table.OQpager {
  margin-left: auto;
  margin-right: auto;
}

.OQcolHeadTitle {
  font-size: 1.1em;
  color: black;
  font-weight: bold;
}

#OQdata tr td {
  border-right: 1px solid #efefef;
}

#OQhead, #OQinfo, #OQdata {
  width: 100%;
}


#OQdoc td {
  padding: 2px 5px 2px 5px;
}


#OQhead {
  background-color: #666666;
}

#OQhead td {
  color: white;
  padding: 0px;
}

#OQdoc button {
  cursor: pointer;
  background-color: #dddddd;
  border: 1px outset #333333;
  font-size: .8em;
  color: #111111;
  padding: 0px;
}

#OQsummary {
  width: 30%
}

#OQcmds button {
  margin-right: 2px;
}

div.OQcolCmds button {
  font-size: 10px;
}
div.OQcolCmds button {
  margin-right: 1px;
}
div.OQcolCmds select {
  margin-top: 3px;
}

#OQinfo {
  background-color: #cccccc;
}

tr.OQdataRowTypeEven {
  background-color: white;
}

tr.OQdataRowTypeOdd {
  background-color: #cccccc;
}

td.OQdataRCol {
  width: 1%;
}

#OQcmds {
  text-align: right;
}

td.OQdataLCol { width: 1%; }
tr.OQupdatedRow { background-color: #ffdddd }

td.OQcolHeader { white-space: nowrap } 

.OQaddColButton, .OQsortAscButton, .OQsortDescButton, .OQfilterCol, .OQcloseButton{
  width: 15px; height: 16px; margin: 0; margin-right: 8px !important; padding: 0;
  border: 0 !important; text-indent: -1000em;
} 

.OQaddColButton { background: transparent url(/OptimalQuery/add.gif) no-repeat center top; }
.OQsortAscButton { background: transparent url(/OptimalQuery/sortDown.gif) no-repeat center top; }
.OQsortDescButton { background: transparent url(/OptimalQuery/sortUp.gif) no-repeat center top; }
.OQfilterCol { background: transparent url(/OptimalQuery/filter.gif) no-repeat center top; }
.OQcloseButton { background: transparent url(/OptimalQuery/close.gif) no-repeat center top; }

#cmdOptions {
  margin-top: 10px;
  position: absolute;
  width: 20em;
  height: 16em;
  right: 20px;
  background-color: #efefef;
  border: 4px groove #666666;
  padding-right: 8px;
  padding-left: 8px;
  padding-bottom: 8px;
  font-size: .8em;
  color: #444444;
  overflow: auto;
  display: none;
}

#cmdOptions button.closeButton {
  position: absolute;
  right: 0;
  color: black;
  font-weight: bold;
  padding: 0px;
  margin: 0px;
  background-color: white;
  border: 1px outset black;
  text-align: center;
  vertical-align: middle;
  cursor: pointer;
  font-size: .8em;
}

#cmdOptions h1 {
  color: #222222;
  margin: 0px;
  font-size: 1.2em;
  padding: 0;
}

#cmdOptions span.note {
  font-size: .7em;
}

#OQdata { border-bottom: 1px solid #666666; }

#OQkey button { margin-left: 10px; }

TILEND
}
















sub can_embed { 1 }

sub getPager {
  my $o = shift;

  my $doc = "
<center>
<table class='OQpager'>
<tr>
<td>";
  # print previous page button if user is not on first page
  $doc .= "<button type='button' class='OQprevPageButton' onclick=\"OQval('page', ".
    ($o->get_current_page() - 1)."); OQrefresh();\">previous</button>"
      if $o->get_current_page() > 1;

  $doc .= "</td>
<td>
<select class='OQrowsPagePicker' onchange=\"OQval('rows_page',this.options[this.selectedIndex].value); OQrefresh();\">";

  # print results per page picker
  foreach my $p (@{ $$o{schema}{results_per_page_picker_nums} }) {
    next if $p ne 'All' && $p > $o->get_count();
    $doc .= "<option value='$p'";
    $doc .= " selected='selected'" if $p eq $o->get_rows_page();
    $doc .= ">View $p results";
    $doc .= " per page" if $p !~ /all/i;
    $doc .= "</option>";
  }
  $doc .= "</select></td>

<td>Page (";
  # print current page picker
  if ($o->get_num_pages() <= 1) {
    $doc .= $o->get_num_pages();
  } else {
    $doc .= "<select class='OQpagePicker' onchange=\"OQval('page',this.options[this.selectedIndex].value); OQrefresh();\">\n";

    # only show page markers for pages 1 - 10,
    # 5 pages before current page, 5 pages after current page, and last 10 pages
    my @page_markers_to_show = sort { $a <=> $b } (
      (1 .. 10),
      (($$o{page} - 5) .. ($$o{page} + 5)),
      (($o->get_num_pages() - 10) .. $o->get_num_pages() ) );
    my $lastP;
    foreach my $p (@page_markers_to_show) {
      next if $p < 1 || $p == $lastP || $p > $o->get_num_pages();
      $doc .= "<option value='$p'";
      $doc .= " selected='selected'" if $p == $$o{page};
      $doc .= ">".$o->commify($p);
      $doc .= "</option>";
      $lastP = $p;
    }
    $doc .= "</select>\n";
  }

  $doc .= " of ".$o->commify($o->get_num_pages).")</td><td>\n";

  # print previous page button if user is not on last page
  $doc .= "<button type='button' class='OQnextPageButton' onclick=\"OQval('page', ".($$o{page} + 1).")
; OQrefresh();\">next</button>" if $$o{page} < $o->get_num_pages();
  $doc .= "</td>
</tr>
</table>
</center>";

  return $doc;
}


sub output {
  my $o = shift;
  my $current_pack = __PACKAGE__;
  my %opts;
  %opts = %{ $$o{schema}{options}{$current_pack} } if exists $$o{schema}{options}{$current_pack};

  $opts{httpHeader} = $$o{q}->header('text/html') if ! exists $opts{httpHeader};


  my $inlineCSS = "\n<style type='text/css' id='OQstyle'>";
  if (! exists $opts{htmlHeader}) {
    my $title = $opts{title} || 'OptimalQuery Report';
    $opts{htmlHeader} = "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN' 'http://www.w3.org/TR/html4/strict.dtd'>
<html>
<head>
<title>".$o->escape_html($title)."</title>
</head>
<body style=\"margin: 0; background-color: white;\">";
    $inlineCSS .= ($opts{replaceCSS} || get_defaultCSS());
    $inlineCSS .= $opts{appendCSS} if exists $opts{appendCSS};

    # replace default title bar color if color is defined
    if (exists $opts{color}) {
      my $color = $opts{color};
      $inlineCSS =~ s/(\#OQhead \s* \{   (?# find OQhead selector)
                  [^}]*?           (?# read past rules before background-color)
                  background\-color\:\s*)  (?# find background-color rule)
                .*\;               (?# old defined color)
               /$1$opts{color};/x;
    }

    # replace url(/OptimalQuery/ with custom resourceURI if it exists
    if (exists $$o{schema}{resourceURI}) {
      $$o{schema}{resourceURI} =~ s/\/$//;
      $inlineCSS =~ s/(?<=\burl\()   (?# match before)
                .*?            (?# stuff to replace)
                (?=\/\w+\.gif) (?# match after)
               /$$o{schema}{resourceURI}/xg;
    }
  }
  $inlineCSS .= "#OQfilter { display: none; }\n"     if $$o{filter} eq '';
  $inlineCSS .= "#OQsort { display: none; }\n"       if $$o{sort} eq '';
  $inlineCSS .= "#OQqueryDescr { display: none; }\n" if $$o{queryDescr} eq '';
  $inlineCSS .= "\n</style>\n";
  if (!($opts{htmlHeader} =~ s/(<\/head>)/$inlineCSS$1/i)) {
    $opts{htmlHeader} .= $inlineCSS;
  }

  $opts{htmlFooter} = "</body>\n</html>\n"
    unless exists $opts{htmlFooter};

  # eval if code ref 
  foreach my $key (qw( OQdocTop OQdocBottom OQformTop OQformBottom )) {
    $opts{$key} = $opts{$key}->() if ref($opts{$key}) eq 'CODE';
  }

  $opts{OQdocTop}      ||= '';
  $opts{OQdocBottom}   ||= '';
  $opts{OQformTop}     ||= '';
  $opts{OQformBottom}  ||= '';
  $opts{editButtonLabel} ||= 'edit';
  $opts{disable_sort} ||= 0;
  $opts{disable_filter} ||= 0;
  $opts{disable_select} ||= 0;
  $opts{mutateRecord}  ||= undef;
  $opts{noEscapeCol}   ||= [];
  $opts{editLink}      ||= undef;

  # carry hidden state params
  my $state_params = '';
  if (ref($$o{schema}{state_params}) eq 'ARRAY') {
    foreach my $p (@{ $$o{schema}{state_params} }) {
      $state_params .= ";$p=".$o->escape_uri($o->{q}->param($p));
    }
  }
  $state_params .= ';' if $state_params;



  my $doc = $opts{httpHeader}.$opts{htmlHeader}."
<div id='OQdoc'>
<div id='OQdocTop'>$opts{OQdocTop}</div>

<form id='OQform' name='OQform' action='".$$o{schema}{URI}."#OQtop' method='post'>
<input type='hidden' name='act' value='' />
<input type='hidden' name='view' value='' />

<script type='text/javascript' id='OQscript'>

// code to open debug mode when ALT-Q is typed
var last_key;
if (window.document.getElementById) document.onkeyup = KeyCheck;
function KeyCheck(e) {
  var KeyID = (window.event) ? event.keyCode : e.keyCode;
  if (last_key == 18 && KeyID == 81) { 
    if (window.document.getElementById &&
        window.document.getElementById('OQstateVars') &&
        window.document.getElementById('OQstateVars').style ) {
      var d = window.document.getElementById('OQstateVars').style.display;
      d = (d == 'none') ? '' : 'none';
      window.document.getElementById('OQstateVars').style.display = d;
    }
  }
  else { last_key = KeyID; }
  return true;
} 



var OQdefaultModule = 'InteractiveQuery';
function OQval(name, newVal) {
  if (document.OQform.elements[name]) {
    var elem = document.OQform.elements[name];
    if (newVal != null) elem.value = newVal;
    return elem.value;
  }
}
function OQvals(name, newVals) {
  if (document.OQform.elements[name]) {
    var elem = document.OQform.elements[name];
    if (newVals != null) elem.value = newVals.join(',');
    if (elem.value == '') return new Array();
    else return elem.value.split(',');
  }
}

function OQrefresh(updated_uid) {
  var f = document.OQform;
  f.target = '';
  f.module.value = OQdefaultModule;
  f.act.value = '';
  f.view.value = '';

  if (updated_uid && f.on_select.value != '') {
    funct_ref = eval('window.opener.'+f.on_select.value);
    if (funct_ref) {
      funct_ref(updated_uid);
      window.opener.focus();
    } 
    window.close();
  }
  else {
    if (updated_uid) f.updated_uid.value = updated_uid;
    f.action = '$$o{schema}{URI}#OQtop';
    f.submit();
  }
}


// special open window code (auto centers based on parent)
function OQopwin (lnk,target,opts,w,h) {

 if (! target) target = '_blank';
 if (! opts) opts = 'resizable,scrollbars';
 if (! w) w = $$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowWidth};
 if (! h) h = $$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowHeight};

 if (window.screen) {
    var s = window.screen;
    var max_width = s.availWidth - 10;
    var max_height = s.availHeight - 30;
    if (opts.indexOf('toolbar',0) != -1) max_height -= 40;
    if (opts.indexOf('menubar',0) != -1) max_height -= 35;
    if (opts.indexOf('location',0) != -1)max_height -= 35;
    var width  = (w > max_width)?max_width:w;
    var height = (h > max_height)?max_height:h;
    var par_left_offset = (window.screenX == null)?0:window.screenX;
    var par_top_offset  = (window.screenY == null)?0:window.screenY;
    var par_width;
    if (window.outerWidth != null) {
      par_width = window.outerWidth;
      if (par_width < width)
        par_left_offset -= parseInt((width - par_width)/2);
    } else
      par_width = max_width;

    var par_height;
    if (window.outerHeight != null) {
      par_height = window.outerHeight;
      if (par_height < height) {
        par_top_offset -= parseInt((height - par_height)/2);
      }
    } else
      par_height = max_height;

    var left = parseInt(par_width /2 - width /2) + par_left_offset;
    var top  = parseInt(par_height/2 - height/2) + par_top_offset;

    var newopts = 'width='+width+',height='+height+',left='+left+',top='+top;
    opts = (opts && opts != '')?newopts+','+opts:newopts;
  }
  var wndw = window.open(lnk,target,opts);
  if (wndw.focus) wndw.focus();
  return wndw;
}

function hideCmdOptions() {
  OQval('OQsaveSearchTitle','');
  document.getElementById('cmdOptions').style.display = 'none';
  document.getElementById('exportOptions').style.display = 'none';
  document.getElementById('savedSearchesOptions').style.display = 'none';

  // hack for z-layer form input bug in IE
  if (/MSIE\ 6/.test(navigator.userAgent))
    document.getElementById('OQdata').style.visibility = 'visible';
}

function toogleCmdOptions(id) {
  if (document.getElementById(id).style.display == 'block') {
    hideCmdOptions();
  } else {
    document.getElementById('exportOptions').style.display = 'none';
    document.getElementById('savedSearchesOptions').style.display = 'none';

    if (/MSIE\ 6/.test(navigator.userAgent))
      document.getElementById('OQdata').style.visibility = 'hidden';

    document.getElementById(id).style.display = 'block';
    document.getElementById('cmdOptions').style.display = 'block';
  }
}


</script><noscript>Javascript is required when viewing this page.</noscript>

<table id='OQstateVars' style=\"display: none;\">
<tr>
<td>show</td>
<td><input type='text' name='show' value=\"".$o->escape_html(join(',',@{$$o{show}}))."\" /></td>
</tr>
<tr>
<td>filter</td>
<td><input type='text' name='filter' value=\"".$o->escape_html($$o{filter})."\" /></td>
</tr>
<tr>
<td>hiddenFilter</td>
<td><input type='text' name='hiddenFilter' value=\"".$o->escape_html($$o{hiddenFilter})."\" /></td>
</tr>
<tr>
<td>queryDescr</td>
<td><input type='text' name='queryDescr' value=\"".$o->escape_html($$o{queryDescr})."\" /></td>
</tr>
<tr>
<td>sort</td>
<td><input type='text' name='sort' value=\"".$o->escape_html($$o{sort})."\" /></td>
</tr>
<tr>
<td>page</td>
<td><input type='text' name='page' value=\"".$o->escape_html($$o{page})."\" /></td>
</tr>
<tr>
<td>module</td>
<td><input type='text' name='module' value=\"".$o->escape_html($$o{module})."\" /></td>
</tr>
<tr>
<td>rows_page</td>
<td><input type='text' name='rows_page' value=\"".$o->escape_html($$o{rows_page})."\" /></td>
</tr>
<tr>
<td>updated_uid</td>
<td><input type='text' name='updated_uid' value='' /></td>
</tr>
<tr>
<td>on_select</td>
<td><input type='text' name='on_select' value=\"".$o->escape_html($$o{q}->param('on_select'))."\" /></td> 
</tr>";

  if (ref($$o{schema}{state_params}) eq 'ARRAY') {
    foreach my $p (@{ $$o{schema}{state_params} }) {
      $doc .= "<tr><td>$p</td><td><input type='text' name='$p' value='".$o->escape_html($o->{q}->param($p))."'></td></tr>";
    }
  }

  $doc .= "
<tr><td colspan=2><button type='reset'>reset</button> <button type=button onclick=\"this.form.method='GET';this.form.submit();\">submit</button></td></tr></table>

<a name='OQtop'></a>

<div id='OQupdatedUidInfo'>".
(($$o{q}->param('updated_uid') eq '')?"":
  "UID: ".$o->escape_html($$o{q}->param('updated_uid'))." updated")."
</div>


<div id='OQformTop'>$opts{OQformTop}</div>

<table id='OQhead'>
<tr>
<td id='OQtitle'>".$o->escape_html($o->get_title)."</td>
<td id='OQsummary'>Result(s) (".$o->commify($o->get_lo_rec)." - ".$o->commify($o->get_hi_rec).") of ".$o->commify($o->get_count)."</td>
<td id='OQcmds'>";

  if (ref($opts{buildNewLink}) eq 'CODE') {
    my $link = $opts{buildNewLink}->($o, \%opts); 
    if ($link ne '') {
      $doc .= "<button type='button' class='OQnewButton' onclick=\"OQopwin('$link','_blank','resizable,scrollbars',$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowWidth},$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowHeight});\">new</button>";
    }
  }
  elsif (exists $opts{buildNewLink} && $opts{buildNewLink} eq '') {}
  elsif ($opts{editLink} ne '') {
    my $link = $opts{editLink}.(($opts{editLink} =~ /\?/)?'&':'?')."on_update=OQrefresh&act=new";
    if ($link ne '') {
      $doc .= "<button type='button' class='OQnewButton' onclick=\"OQopwin('$link','_blank','resizable,scrollbars',$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowWidth},$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowHeight});\">new</button>";
    }
  }

  $doc .= "<button type='button' class='OQrefreshButton' onclick=\"OQrefresh();\">refresh</button>";
  $doc .= "<button type='button' onclick=\"toogleCmdOptions('savedSearchesOptions'); 
if (document.getElementById('savedSearchesOptions').style.display != 'none') this.form.OQsaveSearchTitle.focus();
\">saved searches</button>" if $$o{schema}{savedSearchUserID};
  $doc .= "<button type='button' onclick=\"toogleCmdOptions('exportOptions');\">export</button>
</td>
</tr>
</table>

<div id='cmdOptions'>
  <button type='button' class='closeButton' onclick=\"hideCmdOptions();\" title='close'>&times;</button>

<div id='exportOptions'>
  <h1>select download file type</h1>
  <input type='radio' name='exportModule' checked = 'checked'/>Printer Friendly
  <br />
  <input type='radio' name='exportModule' />CSV <span class='note'>comma separated values (use in Microsoft Excel)</span>
  <br />
  <input type='radio' name='exportModule' />XML ";

  if ($$o{rows_page} ne 'All') {
    $doc .= " <br /> <input type='checkbox' name='exportAll' />export all results"
  }
  $doc .= "
  <br />
  <button type='button' onclick=\" hideCmdOptions(); var f = this.form; if (f.exportModule[0].checked) { f.module.value = 'PrinterFriendly'; f.target = '_blank'; } else if (f.exportModule[1].checked) f.module.value = 'CSV'; else if (f.exportModule[2].checked) f.module.value = 'XML'; if (f.exportAll &amp;&amp; f.exportAll.checked) { var tmp = f.rows_page.value; f.rows_page.value = 'All'; window.setTimeout('OQval(\\x27rows_page\\x27,\\x27' + tmp + '\\x27)', 1000); } f.action = '$$o{schema}{URI_standalone}'; f.submit(); \">download</button>
</div>

<div id='savedSearchesOptions'>
";

  
  # if saved searches are enabled ..
  if ($$o{schema}{savedSearchUserID}) {
    local $$o{dbh}->{LongReadLen};
    $doc .= "
  <h1>save search</h1>
  name <input type=text name='OQsaveSearchTitle' value='' /><button type='button' title='save search' onclick=\"OQrefresh();\">save</button><br /> <br />";

    if ($$o{dbh}{Driver}{Name} eq 'Oracle') {
      my ($readLen) = $$o{dbh}->selectrow_array("SELECT max(dbms_lob.getlength(params)) FROM oq_saved_search WHERE user_id = ?", undef, $$o{schema}{savedSearchUserID});
      $$o{dbh}->{LongReadLen} = $readLen if $readLen > $$o{dbh}->{LongReadLen};
    }

    my $sth = $$o{dbh}->prepare("
      SELECT id, user_title, params
      FROM oq_saved_search
      WHERE user_id = ? 
      AND upper(uri) = upper(?)
      AND oq_title = ?");
    $sth->execute($$o{schema}{savedSearchUserID}, $$o{schema}{URI},$$o{schema}{title});

    my $buffer = '';
    while (my ($id, $title, $params) = $sth->fetchrow_array()) {

      my $stateArgs = '';
      if ($params ne '') {
        $params = eval '{'.$params.'}';
        if (ref($params) eq 'HASH') {
          delete $$params{show};
          delete $$params{rows_page};
          delete $$params{page};
          delete $$params{hiddenFilter};
          delete $$params{filter};
          delete $$params{queryDescr};
          delete $$params{sort};
          while (my ($k,$v) = each %$params) {
            $stateArgs .= "&amp;$k=";
            $stateArgs .= (ref($v) eq 'ARRAY') ? 
              CGI::escape($$v[0]) : CGI::escape($v);
          }
        }
      }

      $buffer .= "<a href=# onclick=\"window.location='$$o{schema}{URI}?OQLoadSavedSearch=$id".$stateArgs."#OQtop';\">".$o->escape_html($title)."</a><br />"; 
    }
    $doc .= "<h1>load search</h1>$buffer" if $buffer;
  }

  $doc .= "
</div>
</div>
<table id='OQinfo' style=\"border-bottom: 1px solid #666666;\">";

  if (!( $opts{disable_select} && $opts{disable_sort} && $opts{disable_filter} )) {
    $doc .= "
<tr id='OQkey'><td class='OQinfoName'>Key:</td>
<td class='OQinfoVal'>";

    $doc .= "<button class='OQaddColButton' type='button'>add column</button>add column"
      unless $opts{disable_select};

    $doc .= "<button class='OQsortAscButton' type='button'>sort</button>sort
<button class='OQsortDescButton'>reverse sort</button>reverse sort"
      unless $opts{disable_sort};

    $doc .= "<button class='OQfilterCol' type='button'>filter column</button>filter column"
      unless $opts{disable_filter};

    $doc .= "<button class='OQcloseButton' type='button'>close column</button>close column"
      unless $opts{disable_select};
    $doc .= "</td></tr>";
  }
  $doc .= "
<tr id='OQqueryDescr'><td class='OQinfoName'>Query:</td><td class='OQinfoVal'>".$o->escape_html($$o{queryDescr})."</td></tr>
<tr id='OQfilter'><td class='OQinfoName'>Filter:</td><td class='OQinfoVal'>".$o->escape_html($o->get_filter());

  $doc .= "<button class='OQfilterCol' title='filter query' type=\"button\" onclick=\"OQopwin('$$o{schema}{URI_standalone}?module=InteractiveFilter;".$state_params."filter='+escape(OQval('filter')),'filter','resizable,scrollbars',760,300);\">filter</button>" unless $opts{disable_filter};

  $doc .= 
"</td></tr>
<tr id='OQsort'><td class='OQinfoName'>Sort:</td><td class='OQinfoVal'>";

  my @sort = $o->sth->sort_descr();
  if (@sort) {
    # create new sort description
    my @buffer;
    for (my $i=0; $i < @sort; $i++) {
      my $buf = '';
      $buf .= "<a href='#' title='remove sort' onclick=\"var sort=OQvals('sort');sort.splice($i,1);OQvals('sort',sort);OQrefresh(); return false;\">" unless $opts{disable_sort};
      $buf .= $o->escape_html($sort[$i]);
      $buf .= "</a>" unless $opts{disable_sort};  
      push @buffer, $buf;
    }
    $doc .= join(', ',@buffer);
  }

  $doc .= "</td></tr>
</table>

<table id='OQdata'>
<thead>
<tr>

<td id='OQdataLHead'>
</td>";




  foreach my $i (0 .. ($o->get_num_usersel_cols() - 1)) {
    my $colAlias = $o->get_usersel_cols->[$i];
    $doc .= "<td class='OQcolHeader'><div class='OQcolCmds'>
<!-- the following line is necessary for IE browsers otherwise buttons won't display -->
<span style='visibility: hidden;'>.</span>
";

    if (! ($$o{schema}{select}{$colAlias}[3]{disable_select} || $opts{disable_select})) {
      $doc .= "<button type='button' class='OQaddColButton' title='add column' onclick=\"var show=OQvals('show');show.splice($i,0,'$colAlias');OQvals('show',show);OQrefresh();\">add</button>";
    }
    if (! ($$o{schema}{select}{$colAlias}[3]{disable_sort} || $opts{disable_sort}) ) {
      $doc .= "<button type='button' title='sort' class='OQsortAscButton' onclick=\"var sort=OQvals('sort');sort.push('[$colAlias]'); OQvals('sort',sort);OQrefresh();\">sort</button>
<button type='button' title='reverse sort' class='OQsortDescButton' onclick=\"var sort=OQvals('sort');sort.push('[$colAlias] DESC');OQvals('sort',sort);OQrefresh();\">reverse sort</button>";
    } 
    if (! ($$o{schema}{select}{$colAlias}[3]{disable_filter} || $opts{disable_filter}) ) {
      $doc .= "<button type='button' title='filter column' class='OQfilterCol' onclick=\"OQopwin('$$o{schema}{URI_standalone}?module=InteractiveFilter;".$state_params."filter='+escape(OQval('filter'))+';NEXT_EXPR='+escape('$colAlias'),'filter','resizable,scrollbars',760,300);\">filter</button>";
    }
    if (! ($$o{schema}{select}{$colAlias}[3]{disable_select} || $opts{disable_select})) {
      $doc .= "<button type='button' title='close column' class='OQcloseButton' onclick=\"var show=OQvals('show');show.splice($i,1);OQvals('show',show);OQrefresh();\">close</button><br />";
    }

    if ($$o{schema}{select}{$colAlias}[3]{disable_select} || $opts{'disable_select'}) {
      $doc .= "<div class='OQcolHeadTitle'>".$o->escape_html($$o{schema}{select}{$colAlias}[2])."</div>";
    } 

    else {
      $doc .= "<select class='OQcolSelect' title='select a different column to view' onchange=\"var show=OQvals('show');show.splice($i,1,this.options[this.selectedIndex].value);OQvals('show',show);OQrefresh();\">";

      # create possible cols to select
      my $s = $$o{schema}{select};

      foreach my $col (sort { uc($s->{$a}->[2]) cmp uc($s->{$b}->[2]) } keys %{$$o{schema}{select}}) {
        my $col_opts = $s->{$col}->[3] || {};
        next if $col_opts->{'is_hidden'} || ! $$s{$col}[2];
        my $nice = $o->get_nice_name($col);

        $doc .= "<option value='".$o->escape_html($col)."'";
        $doc .= " selected='selected'" if ($o->{'show'}->[$i] eq $col);
        $doc .= ">".$o->escape_html($nice)."</option>";
      }
      $doc .= "</select>";
    }

    $doc .= "</div></td>";
  }

  $doc .= "
<td id='OQdataRHead'></td>
</tr>
</thead>

<tfoot id='OQdataFoot'>
</tfoot>

<tbody>";

  # print data
  my $rowType = 'Odd';

  my %noEsc = map { $_ => 1 } @{ $opts{noEscapeCol} };

  my $recs_in_buffer = 0;
  while (my $r = $o->sth->fetchrow_hashref()) {
    $opts{mutateRecord}->($r) if ref($opts{mutateRecord}) eq 'CODE';
    $$o{schema}{mutateRecord}->($r) if ref($$o{schema}{mutateRecord}) eq 'CODE';

    my $class = "OQdataRowType$rowType";
    $class .= " OQupdatedRow"
      if $$r{U_ID} ne '' && $$r{U_ID} eq $$o{q}->param('updated_uid');

    $doc .= "<tr class='$class'>\n<td class='OQdataLCol'>";
    if (ref($opts{OQdataLCol}) eq 'CODE') { $doc .= $opts{OQdataLCol}->($r); }
    elsif (ref($opts{buildEditLink}) eq 'CODE') {
      my $link = $opts{buildEditLink}->($o, $r, \%opts);
      if ($link ne '') {
        $doc .= "<button type='button' class='OQeditButton' onclick=\"OQopwin('$link','_blank','resizable,scrollbars',$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowWidth},$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowHeight});\">$opts{editButtonLabel}</button>";
      }
    } elsif ($opts{editLink} ne '' && $$r{U_ID} ne '') {
      my $link = $opts{editLink}.(($opts{editLink} =~ /\?/)?'&':'?')."on_update=OQrefresh&act=load&id=$$r{U_ID}";
      $doc .= "<button type='button' class='OQeditButton' onclick=\"OQopwin('$link','_blank','resizable,scrollbars',$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowWidth},$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}{WindowHeight});\">$opts{editButtonLabel}</button>";
    }
    $doc .= "\n</td>";

    # print table cell with value
    foreach my $col (@{ $o->get_usersel_cols }) {
      my $val;
      if (exists $noEsc{$col}) {
        $val = $$r{$col};  
      } else {
        if (ref($$r{$col}) eq 'ARRAY') {
          $val = join(', ', map { $o->escape_html($_) } @{ $$r{$col} }); 
        } else {
          $val = $o->escape_html($$r{$col});
        }
      }
      $doc .= "<td class='OQcolData OQselect-$col'>$val</td>\n";
    }

    # still need to add code for on_select functionality
    $doc .= "<td class='OQdataRCol'>\n";

    if (ref($opts{OQdataRCol}) eq 'CODE') { $doc .= $opts{OQdataRCol}->($r); }
    elsif ($o->{q}->param('on_select') ne '' && $$r{U_ID} ne '') {
      my $on_select = $o->{q}->param('on_select');
      $doc .= "<button type='button' onclick=\"if (window.opener &amp;&amp; window.opener.$on_select) window.opener.$on_select('$$r{U_ID}'); window.close();\">select</button>";
    }

    $doc .= "\n</td>\n</tr>\n\n";

    $rowType = ($rowType eq "Odd") ? "Even" : "Odd";

    $recs_in_buffer++;
    if ($recs_in_buffer == 20) { $$o{output_handler}->($doc); $doc = ''; $recs_in_buffer = 0; }
  }
  $o->sth->finish();

  $doc .= "
</tbody>
</table>";

  $doc .= $o->getPager();

  $doc .= "
<div id='OQformBottom'>".$opts{OQformBottom}."</div>
</form>

<script type='text/javascript'>
$opts{OQscript}
document.OQform.reset();
</script><noscript>Javascript is required when viewing this page.</noscript>

<div id='OQdocBottom'></div>
</div>
$opts{htmlFooter}";

  $$o{output_handler}->($doc);
  return undef;
}

1;
