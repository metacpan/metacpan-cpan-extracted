#
# This test suite tests the methods most closely associated with LWP and the user agent, bjd 2013
# 

use Test::More tests => 10;
use Astro::ADS::Query;

ok( $query = new Astro::ADS::Query(), 'Creating a query object');
is( $query->url(), 'cdsads.u-strasbg.fr', 'Defaults to strasbourg');
ok( $query->url('ukads.nottingham.ac.uk'), 'Change to Nottingham');
is( $query->url(), 'ukads.nottingham.ac.uk', 'Should reflect change of site to Nottingham');

is( $query->proxy(), $ENV{HTTP_PROXY}, 'Proxy picked up from environment variable');
diag("My Version: ", $Astro::ADS::Query::VERSION);
diag("User Agent: ", $query->agent());
like( $query->agent(), qr{^Astro::ADS/$Astro::ADS::Query::VERSION \(.+\)$}, 'get the useragent string');
ok( $query->agent('Test Suite'), 'Add information to useragent string');
like( $query->agent(), qr{^Astro::ADS/$Astro::ADS::Query::VERSION \[Test Suite\] \(.+\)$}, 'get the modified useragent string');
ok( $query->agent(''), 'remove information from useragent string');
like( $query->agent(), qr{^Astro::ADS/$Astro::ADS::Query::VERSION \[\] \(.+\)$}, 'get the removed useragent string');
