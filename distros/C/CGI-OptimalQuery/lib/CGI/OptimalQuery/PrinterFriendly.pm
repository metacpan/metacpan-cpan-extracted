package CGI::OptimalQuery::PrinterFriendly;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';
use POSIX qw( strftime );

sub output {
  my $o = shift;

  my $buf;

  my $fn = $o->{schema}->{title};
  { my @t = localtime;
    $fn .= '_'.($t[5] + 1900).($t[4] + 1).$t[3].'.html';
    $fn =~ s/\s+/\_/g;
  }

  my $title = ($o->{schema}->{title});
  if ($$o{queryDescr}) {
    $title .= " - $$o{queryDescr}";
  }
  my $v = $o->escape_html($o->get_filter());
  if ($v) {
    $title .= " - $v";
  }
  if ($o->get_hi_rec < $o->get_count) {
    $title .= ' results: '.$o->commify($o->get_lo_rec)." - ".$o->commify($o->get_hi_rec);
  }

  $buf .= $$o{httpHeader}->(-type => 'text/html', -attachment => $fn);
  $buf .= '<!DOCTYPE HTML>
<html>
<head>
<title>'.$o->escape_html($title).'</title>
<style>
body {
  margin: 0;
  background-white;
  font-family: sans-serif;
  font-size: 12px;
}
dl {
  margin:0;
}
dt,dd {
  float: left;
  margin: 0;
}
dt {
  clear:both;
  width: 5em;
  font-weight: bold;
}
table {
  border-collapse: collapse;
}
td {
  padding: 0 3px;
}
thead td {
  font-weight: bold;
  text-decoration: underline;
}
tbody td {
  border-bottom: 1px solid #ddd;
}
#OQdata {
  clear: both;
}
</style>
</head>
<body>
<table id=OQdata>
<thead>
<tr>';

  my @userselcols = @{ $o->get_usersel_cols };
  foreach my $i (0 .. $#userselcols) {
    my $colAlias = $o->get_usersel_cols->[$i];
    my $nice = $o->get_nice_name($colAlias) || $colAlias;
    $buf .= "<td>".$o->escape_html($nice)."</td>";
  }
  $buf .= "
</tr>
</thead>
<tbody>";

  my $i = 0;

  while (my $r = $o->fetch()) {
    $buf .= "<tr>";
    foreach my $col (@userselcols) {
      $buf .= "<td>".$o->get_val($col)."</td>";
    }
    $buf .= "</tr>\n";

    # flush
    if (++$i == 10000) {
      $$o{output_handler}->($buf);
      $buf = '';
      $i=0;
    }
  }
  $o->finish();

  $$o{output_handler}->($buf);
  $buf .= "
</tbody>
</table>
</body>
</html>";

  return undef;
}

1;
