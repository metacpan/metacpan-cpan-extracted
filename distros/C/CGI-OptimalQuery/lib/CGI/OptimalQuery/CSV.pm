package CGI::OptimalQuery::CSV;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';
use CGI();

sub output {
  my $o = shift;

  my $title = $o->{schema}->{title};
  $title =~ s/\W//g;
  my @t = localtime;
  $title .= '_'.($t[5] + 1900).($t[4] + 1).$t[3].$t[2].$t[1];

  $$o{output_handler}->($$o{httpHeader}->(-type => 'text/csv', -attachment => "$title.csv"));

  my $selCols = $o->get_usersel_cols();

  # print header
  my @buffer;
  foreach my $i (0 .. $#$selCols) {
    my $col = $o->get_nice_name($o->get_usersel_cols->[$i]);
    $col =~ s/\"/""/g;
    push @buffer, '"'.$col.'"';
  }
  $$o{output_handler}->(join(',', @buffer)."\n");

  # print data
  while (my $rec = $o->fetch()) {
    @buffer = ();
    foreach my $col (@$selCols) {
      my $val = $o->get_val($col);
      $val =~ s/\"/""/g;
      $val =~ s/[\r\n]+/; /g;
      $val =~ s/[^!-~\s]//g;
      push @buffer, '"'.$val.'"';
    }
    $$o{output_handler}->(join(',', @buffer)."\n");
  }
  $o->finish();
  return undef;
}


1;
