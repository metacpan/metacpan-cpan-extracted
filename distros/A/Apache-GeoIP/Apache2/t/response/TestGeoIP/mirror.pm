package TestGeoIP::mirror;
use Apache2::Geo::Mirror;
use strict;
use warnings FATAL => 'all';

use Apache2::Const -compile => 'OK';
use Apache2::RequestIO ();   # for $r->print
use Apache2::RequestRec ();  # for $r->content_type

sub handler {
  my $r = Apache2::Geo::Mirror->new(shift);
  $r->content_type('text/plain');
  my $ip = $r->args;
  my $mirror;
  if ($ip =~ /^\d/) {
    $mirror = $r->find_mirror_by_addr($ip);
  }
  else {
    $mirror = $r->find_mirror_by_country($ip);

  }
  
  $r->print($mirror);
  
  Apache2::Const::OK;
}
1;

__DATA__
<NoAutoConfig>
<Location /cpan>
  SetHandler modperl
  PerlResponseHandler TestGeoIP::mirror
  PerlSetVar GeoIPMirror "@ServerRoot@/conf/cpan_mirror.txt"
  PerlSetVar GeoIPFlag MEMORY_CACHE
</Location>

<Location /apache>
  SetHandler modperl
  PerlResponseHandler TestGeoIP::mirror
  PerlSetvar GeoIPMirror "@ServerRoot@/conf/apache_mirror.txt"
  PerlSetVar GeoIPDefault "http://httpd.apache.org"
</Location>

PerlModule Apache2::Geo::Mirror
<Location /mirror>
  SetHandler modperl
  PerlResponseHandler Apache2::Geo::Mirror->auto_redirect
  PerlSetvar GeoIPMirror "@ServerRoot@/conf/auto_mirror.txt"
  PerlSetVar GeoIPDefault "http://www.apache.org"
</Location>

<Location /mirror_fresh>
  SetHandler modperl
  PerlResponseHandler Apache2::Geo::Mirror->auto_redirect
  PerlSetvar GeoIPMirror "@ServerRoot@/conf/auto_mirror_fresh.txt"
  PerlSetVar GeoIPDefault "http://www.gnu.org"
  PerlSetVar GeoIPFresh 2
</Location>

<Location /mirror_robot_default>
  SetHandler modperl
  PerlResponseHandler Apache2::Geo::Mirror->auto_redirect
  PerlSetvar GeoIPMirror "@ServerRoot@/conf/gnu_mirror.txt"
  PerlSetVar GeoIPDefault "http://www.gnu.org"
  PerlSetVar GeoIPRobot default
</Location>

<Location /mirror_robot>
  SetHandler modperl
  PerlResponseHandler Apache2::Geo::Mirror->auto_redirect
  PerlSetvar GeoIPMirror "@ServerRoot@/conf/gnu_mirror.txt"
  PerlSetVar GeoIPDefault "http://www.gnu.org"
  PerlSetVar GeoIPRobot "@ServerRoot@/conf/robots.txt"
</Location>

</NoAutoConfig>
