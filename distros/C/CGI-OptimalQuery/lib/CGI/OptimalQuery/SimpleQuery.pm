package CGI::OptimalQuery::SimpleQuery;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';

sub escapeHTML { CGI::OptimalQuery::Base::escapeHTML(@_) }

sub output {
  my ($o) = @_;

  my $tbody;
  my $typeMap = $o->{oq}->get_col_types('select');
  while (my $r = $o->fetch()) {
    $tbody .= "<tr data-uid='".escapeHTML($$r{U_ID})."'>";

    foreach my $col (@{ $o->get_usersel_cols }) {
      my $val = $o->get_html_val($col);
      my $type = $$typeMap{$col} || 'char';
      $tbody .= "<td".(($type ne 'char')?" class=$type":"").">$val</td>";
    }
    $tbody .= "</tr>\n";
  }
  $o->finish();

  my $buf = $$o{httpHeader}->(-type=>'text/html',-expires=>'now')."<!DOCTYPE html>\n<html>\n<body>";

  if ($tbody) {
    $buf .= "<table class=grid><thead><tr>\n";

    foreach my $colAlias (@{ $o->get_usersel_cols }) {
      my $colOpts = $$o{schema}{select}{$colAlias}[3];
      $buf .= "<td data-col='".escapeHTML($colAlias)."'";
      $buf .= ">".escapeHTML($o->get_nice_name($colAlias))."</td>";
    }
    $buf .= "\n</tr></thead><tbody>\n$tbody</tbody></table>";
  }
  else {
    $buf .= "<em>none found</em>";
  }

  $buf .= "</body></html>";

  $$o{output_handler}->($buf);
  return undef;
}

1;
