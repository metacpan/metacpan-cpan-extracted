package TestGeoIP::basic;
use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestUtil;

use Apache2::Const -compile => 'OK';
use Apache2::RequestIO ();

sub handler {
  my $r = shift;
  plan $r, tests => 5;
  
  eval{ require 5.006001;};
  ok t_cmp($@, "", "require 5.00601");

  ok t_cmp($ENV{MOD_PERL_API_VERSION}, 2, "require mod_perl2");
  eval{ require Apache2::GeoIP;};
  ok t_cmp($@, "", "require Apache2::GeoIP");
  eval{ require Apache2::Geo::IP;};
  ok t_cmp($@, "", "require Apache2::Geo::IP");
  eval{ require Apache2::Geo::Mirror;};
  ok t_cmp($@, "", "require Apache2::Geo::Mirror");
  Apache2::Const::OK;
}

1;
__END__


