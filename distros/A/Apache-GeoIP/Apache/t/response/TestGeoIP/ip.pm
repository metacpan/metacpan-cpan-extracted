package TestGeoIP::ip;
use Apache::Geo::IP;
use strict;
use warnings FATAL => 'all';

use Apache::Constants qw(OK);

sub handler {
  my $r = Apache::Geo::IP->new(shift);
  $r->content_type('text/plain');
  $r->send_http_header;
  my $ip = $r->args;
  my $country = uc($r->country_code_by_addr($ip));
  
  $r->print($country);
  
  OK;
}
1;

__END__

