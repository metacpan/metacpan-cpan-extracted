#!perl -T

use Test::More tests => 4;

use lib 't/lib';

BEGIN {
	use_ok( 'MyApp::Config' );
}

is( MyApp::Config->hostname, 'localhost', 'Default config value expected');
 
is( MyApp::Config->username, 'faceman', 'Overriden config value expected');

is_deeply(
  [ MyApp::Config->clothes ],
  [ qw(top pants flipflops) ],
  "arrayrefs flatten to lists",
);
