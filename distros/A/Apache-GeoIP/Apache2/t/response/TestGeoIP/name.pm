package TestGeoIP::name;
use Apache2::Geo::IP;
use strict;
use warnings FATAL => 'all';

use Apache2::Const -compile => 'OK';
use Apache2::RequestIO ();   # for $r->print
use Apache2::RequestRec ();  # for $r->content_type

sub handler {
  my $r = Apache2::Geo::IP->new(shift);
  $r->content_type('text/plain');
  my $ip = $r->args;
  my $country = uc($r->country_code_by_name($ip));
  
  $r->print($country);
  
  Apache2::Const::OK;
}
1;

