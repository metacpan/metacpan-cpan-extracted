package CGI::OptimalQuery::JSON;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';
use CGI();
use JSON::XS();

sub output {
  my $o = shift;

  my $title = $o->{schema}->{title};
  $title =~ s/\W//g;
  my @t = localtime;
  $title .= '_'.($t[5] + 1900).($t[4] + 1).$t[3].$t[2].$t[1];

  $$o{output_handler}->(CGI::header(-type => 'application/json', -attachment => "$title.json"));

  my @selCols = @{ $o->get_usersel_cols() };
  my @buf = ();
  
  while(my $rec = $o->fetch()) {
    push @buf, JSON::XS->new->utf8->encode($rec);
  }
  
  $$o{output_handler}->('[' . join(',', @buf) . ']');
  
  $o->finish();
  return undef;
}

1;
