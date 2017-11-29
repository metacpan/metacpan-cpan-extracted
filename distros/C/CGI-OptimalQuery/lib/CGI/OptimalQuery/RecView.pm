package CGI::OptimalQuery::InteractiveQuery2;

use strict;
use warnings;
no warnings qw( uninitialized redefine );
use base 'CGI::OptimalQuery::Base';

sub escapeHTML { CGI::OptimalQuery::Base::escapeHTML(@_) }

sub output {
  my $o = shift;

  my %opts = %{ $o->get_opts() };
  
  # evalulate code refs
  for (qw(httpHeader htmlFooter htmlHeader OQdocTop
          OQdocBottom OQformTop OQformBottom )) {
    $opts{$_} = $opts{$_}->($o) if ref($opts{$_}) eq 'CODE';
  }

  # define defaults
  $opts{OQdocTop}       ||= '';
  $opts{OQdocBottom}    ||= '';
  $opts{OQformTop}      ||= '';
  $opts{OQformBottom}   ||= '';
  $opts{editButtonLabel}||= 'edit';
  $opts{disable_sort}   ||= 0;
  $opts{disable_filter} ||= 0;
  $opts{disable_select} ||= 0;
  $opts{mutateRecord}   ||= undef;
  $opts{editLink}       ||= undef;
  $opts{htmlExtraHead}  ||= "";
  if (! exists $opts{usePopups}) {
    $opts{usePopups}=1;
  } else {
    $opts{usePopups}=($opts{usePopups}) ? 1 : 0;
  }
  if (! exists $opts{useAjax}) {
    $opts{useAjax} = $opts{usePopups};
  } else {
    $opts{useAjax}=($opts{useAjax}) ? 1 : 0;
  }

  $opts{httpHeader} = $$o{q}->header(-type=>'text/html',-expires=>'now')
    unless exists $opts{httpHeader};
  $opts{htmlFooter} = "</body>\n</html>\n"
    unless exists $opts{htmlFooter};

  my $newBut;
  if ($opts{NewButton}) {
    $newBut = (ref($opts{NewButton}) eq 'CODE') ? $opts{NewButton}->($o, \%opts) : $opts{NewButton};
  }
  elsif (ref($opts{buildNewLink}) eq 'CODE') {
    my $link = $opts{buildNewLink}->($o, \%opts);
    if ($link ne '') {
      $newBut = "<button type=button title=new class=OQnewBut";
      if ($opts{usePopups}) {
        my $target = uc($link); $target =~ s/\W//g;
        $newBut .= " data-target='$target'";
      }
      $newBut .= " data-href='".escapeHTML($link)."'>new</button>";
    }
  }
  elsif (exists $opts{buildNewLink} && $opts{buildNewLink} eq '') {}
  elsif ($opts{editLink} ne '') {
    my $link = $opts{editLink}.(($opts{editLink} =~ /\?/)?'&':'?')."on_update=OQrefresh&act=new";
    if ($link ne '') {
      $newBut = "<button type=button title=new class=OQnewBut";
      if ($opts{usePopups}) {
        my $target = uc($opts{editLink}); $target =~ s/\W//g;
        $newBut .= " data-target='$target'";
      }
      $newBut .= " data-href='".escapeHTML($link)."'>new</button>";
    }
  }

  my $ver = "ver=$CGI::OptimalQuery::VERSION";
  my $buf;
  my $dataonly = $$o{q}->param('dataonly');
  if ($dataonly) {
    $buf = $opts{httpHeader}."<!DOCTYPE html>\n<html><body>";
  } else {
    my $script;
    $script .= "window.OQWindowHeight=$opts{WindowHeight};\n" if $opts{WindowHeight};
    $script .= "window.OQWindowWidth=$opts{WindowWidth};\n" if $opts{WindowWidth};
    $script .= "window.OQuseAjax=$opts{useAjax};\n";
    $script .= "window.OQusePopups=$opts{usePopups};\n";

    if (! exists $opts{htmlHeader}) {
      $opts{htmlHeader} =
"<!DOCTYPE html>
<html>
<head>
<title>".escapeHTML($o->get_title)."</title>
<link id=OQIQ2CSS rel=stylesheet type=text/css href='$$o{schema}{resourceURI}/InteractiveQuery2.css?$ver'>
<meta name=viewport content='width=device-width, initial-scale=1.0, user-scalable=no'>  
".$opts{htmlExtraHead}."</head>
<body id=OQbody>";
    } else {
      $script .= "
  if (! document.getElementById('OQIQ2CSS')) {
    var a = document.createElement('link');
    a.setAttribute('rel','stylesheet');
    a.setAttribute('type','text/css');
    a.setAttribute('id','OQIQ2CSS');
    a.setAttribute('href','$$o{schema}{resourceURI}/InteractiveQuery2.css?1');
    document.getElementsByTagName('head')[0].appendChild(a);
  }\n";
    }

    if ($opts{color}) {
      $script .= "
  var d = document.createElement('style');
  var r = document.createTextNode('.OQhead { background-color: $opts{color}; }');
  d.type = 'text/css';
  if (d.styleSheet)
    d.styleSheet.cssText = r.nodeValue;
  else d.appendChild(r);
  document.getElementsByTagName('head')[0].appendChild(d);\n";
    }

    $buf = $opts{httpHeader}.$opts{htmlHeader};
    $buf .= "<script src=$$o{schema}{resourceURI}/jquery.js?$ver></script><noscript>Javascript is required when viewing this page.</noscript>" unless $opts{jquery_already_sent};
    $buf .= "
<script src=$$o{schema}{resourceURI}/InteractiveQuery2.js?$ver></script><noscript>Javascript is required when viewing this page.</noscript>
<script>
(function(){
$script
})();
</script><noscript>Javascript is required when viewing this page.</noscript>";
    $buf .= "
<div class=OQdocTop>$opts{OQdocTop}</div>";

    # ouput tools panel
    my @tools = sort keys %{$$o{schema}{tools}};
    if ($#tools > -1) {
      $buf .= "<div class=OQToolsPanel-pos-div><div class=OQToolsPanel-align-div><div class=OQToolsPanel><ul>";
      my $opened_tool_key = $$o{q}->param('tool');
      foreach my $key (sort keys %{$$o{schema}{tools}}) {
        my $tool = $$o{schema}{tools}{$key};

        my $openedClass = '';
        my $toolContent = '';
        if ($opened_tool_key eq $key) {
          $openedClass = ' opened';
          $toolContent = "<div class=OQToolContent>".$$tool{handler}->($o)."</div>";
        }
        $buf .= "<li data-toolkey='$key' class='OQToolExpander $openedClass'><h3>".escapeHTML($$tool{title})."</h3>$toolContent</li>";
      }
      $buf .= "</ul><button class=OQToolsCancelBut type=button>&#10005;</button></div></div></div>";
    }
  }
  $buf .= "
<form class=OQform name=OQform action='".escapeHTML($$o{schema}{URI_standalone}||$$o{schema}{URI})."' method=get>
<input type=hidden name=show value='".escapeHTML(join(',',@{$$o{show}}))."'>
<input type=hidden name=filter value='".escapeHTML($$o{filter})."'>
<input type=hidden name=hiddenFilter value='".escapeHTML($$o{hiddenFilter})."'>
<input type=hidden name=queryDescr value='".escapeHTML($$o{queryDescr})."'>
<input type=hidden name=sort value='".escapeHTML($$o{'sort'})."'>
<input type=hidden name=module value='".escapeHTML($$o{module})."'>
<input type=hidden name=OQss value='".escapeHTML($$o{q}->param('OQss'))."'>
<input type=hidden name=on_select value='".escapeHTML($$o{q}->param('on_select'))."'>\n";
  if (ref($$o{schema}{state_params}) eq 'ARRAY') {
    $buf .= "<input type=hidden name='".escapeHTML($_)."' value='"
         .escapeHTML($$o{q}->param($_))."'>\n" for @{$$o{schema}{state_params}};
  }
  $buf .=
"<a name=OQtop></a>
<div class=OQformTop>$opts{OQformTop}</div>

<div class=OQhead>
<div class=OQtitle>".escapeHTML($o->get_title)."</div>
<div class=OQsummary>Result(s) (".$o->commify($o->get_lo_rec)." - "
  .$o->commify($o->get_hi_rec).") of ".$o->commify($o->get_count)."</div>
<div class=OQcmds>
$newBut
<button type=button title='refresh data' class=OQrefreshBut>refresh</button>
<button type=button title='tools' class=OQToolsBut>tools</button>
<button type=button title='help' class=OQhelpBut>help</button>
</div>
</div>

<table class=OQinfo>";
  $buf .= "<tr class=OQQueryDescr><td class=OQlabel>Query:</td><td>".escapeHTML($$o{queryDescr})."</td></tr>" if $$o{queryDescr};

  my $filter = $o->get_filter();
  if ($filter) {
    $buf .= "<tr class=OQFilterDescr title='click to edit filter'";
    $buf .= " data-nofilter" if $opts{disable_filter};
    $buf .= "><td class=OQlabel>Filter:</td><td>".escapeHTML($filter)."</td></tr>";
  }

  my @sort = $o->sth->sort_descr;
  if ($#sort > -1) {
    $buf .= "<tr class=OQSortDescr><td class=OQlabel>Sort:</td><td>";
    my $comma = '';
    foreach my $c (@sort) {
      $buf .= $comma;
      $comma = ', ';
      $buf .= "<a title=remove class=OQRemoveSortBut>" unless $opts{disable_sort};
      $buf .= escapeHTML($c);
      $buf .= "</a>" unless $opts{disable_sort};
    }
    $buf .= "</tr>";
  }
  $buf .= 
"</table>
<table class=OQdata>
<thead title='click to hide, sort, filter, or add columns'>
<tr>
<td class=OQdataLHead></td>";
  foreach my $colAlias (@{ $o->get_usersel_cols }) {
    my $colOpts = $$o{schema}{select}{$colAlias}[3];
    $buf .= "<td data-col='".escapeHTML($colAlias)."'";
    $buf .= " data-noselect" if $$colOpts{disable_select} || $opts{disable_select};
    $buf .= " data-nosort"   if $$colOpts{disable_sort}   || $opts{disable_sort};
    $buf .= " data-nofilter" if $$colOpts{disable_filter} || $opts{disable_filter};
    $buf .= ">".escapeHTML($o->get_nice_name($colAlias))."</td>";
  }
  $buf .= "
<td class=OQdataRHead></td>
</tr>
</thead>
<tbody>\n";

  my $recs_in_buffer = 0;
  my $typeMap = $o->{oq}->get_col_types('select');
  while (my $r = $o->fetch()) {
    $buf .= "<tr data-uid='".escapeHTML($$r{U_ID})."'><td class=OQdataLCol>";
    if (ref($opts{OQdataLCol}) eq 'CODE') {
      $buf .= $opts{OQdataLCol}->($r);
    } elsif (ref($opts{buildEditLink}) eq 'CODE') {
      my $link = $opts{buildEditLink}->($o, $r, \%opts);
      if ($link ne '') {
        $buf .= "<a href='".escapeHTML($link)."' title='open record' class=OQeditBut>".$opts{editButtonLabel}."</a>";
      }
    } elsif ($opts{editLink} ne '' && $$r{U_ID} ne '') {
      my $link = $opts{editLink}.(($opts{editLink} =~ /\?/)?'&':'?')."on_update=OQrefresh&act=load&id=$$r{U_ID}";
      $buf .= "<a href='".escapeHTML($link)."' title='open record' class=OQeditBut>".$opts{editButtonLabel}."</a>";
    }
    $buf .= "</td>";
    foreach my $col (@{ $o->get_usersel_cols }) {
      my $val = $o->get_html_val($col);
      my $type = $$typeMap{$col} || 'char';
      $buf .= "<td".(($type ne 'char')?" class=$type":"").">$val</td>";
    }
    $buf .= "<td class=OQdataRCol>";
    if (ref($opts{OQdataRCol}) eq 'CODE') {
      $buf .= $opts{OQdataRCol}->($r);
    } elsif ($o->{q}->param('on_select') ne '') {
      my $on_select = $o->{q}->param('on_select');
      $on_select =~ s/\~.*//;
      my ($func,@argfields) = split /\,/, $on_select;
      $argfields[0] = 'U_ID' if $#argfields==-1;
      my @argvals = map {
        my $v=$$r{$_};
        $v = join(', ', @$v) if ref($v) eq 'ARRAY';
        $v =~ s/\~\~\~//g;
        $v;
      } @argfields;
      $buf .= "<button type=button title='select record' class=OQselectBut data-rv='"
        .escapeHTML(join('~~~',@argvals))."'>select</button>";
    }
    $buf .= "</td></tr>\n";
    if (++$recs_in_buffer == 10000) {
      $$o{output_handler}->($buf);
      $buf = '';
      $recs_in_buffer = 0;
    }
  }
  $o->finish();

  $buf .= "</tbody></table>\n";

  my $numpages = $o->get_num_pages();

  $buf .= "<div class=OQPager>\n";
  if ($numpages != 1) {
    $buf .= "<button type=button title='previous page' class=OQPrevBut";
    $buf .= " disabled" if $$o{page}==1;
    $buf .= ">&lt;</button>";
  }
  $buf .= " <select name=rows_page>";
  foreach my $p (@{ $$o{schema}{results_per_page_picker_nums} }) {
    $buf .= "<option value=$p".(($p eq $$o{rows_page})?" selected":"").">view $p results per page";
  }
  $buf .= "</select>";
  if ($numpages != 1) {
    $buf .= " <label>Page <input type=number min=1 max=$numpages step=1 name=page value='"
.escapeHTML($$o{page})."'> of $numpages</label> <button type=button title='next page' class=OQNextBut>&gt;</button>"
  }
  $buf .= "
</div>
<div class=OQformBottom>$opts{OQformBottom}</div>
<div class=OQBlocker></div>
<div class=OQColumnCmdPanel>
  <button type=button class=OQLeftBut title='move column left'>move left</button>
  <button type=button class=OQRightBut title='move column right'>move right</button>
  <button type=button class=OQSortBut title='sort column A-Z'>sort</button>
  <button type=button class=OQReverseSortBut title='reverse sort column Z-A'>sort reverse</button>
  <button type=button class=OQFilterBut title='filter column'>filter</button>
  <button type=button class=OQAddColumnsBut title='add columns'>add columns</button>
  <button type=button class=OQCloseBut title='hide column'>hide column</button>
</div>
</form>";

  if ($dataonly) {
    $buf .= "</body></html>";
  } else {

    $buf .= "<div class=OQdocBottom>$opts{OQdocBottom}</div>";
    $buf .= $opts{htmlFooter};
  }

  $$o{output_handler}->($buf);

  return undef;
}


1;
