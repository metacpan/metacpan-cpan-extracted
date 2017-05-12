package TestGeoIP::basic;
use strict;
use warnings FATAL => 'all';

use Apache::Constants qw(OK);
use Apache::Test;
use Apache::TestUtil;

sub handler {
  my $r = shift;
  plan $r, tests => 5;
  
  eval{ require 5.006001;};
  ok t_cmp($@, "", "require 5.00601");
  ok t_cmp(exists $ENV{MOD_PERL}, 1, "require mod_perl");
  eval{ require Apache::GeoIP;};
  ok t_cmp($@, "", "require Apache::GeoIP");
  eval{ require Apache::Geo::IP;};
  ok t_cmp($@, "", "require Apache::Geo::IP");
  eval{ require Apache::Geo::Mirror;};
  ok t_cmp($@, "", "require Apache::Geo::Mirror");
  Apache::OK;
  
  OK;
}
1;

__END__
