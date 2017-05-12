#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache2::SiteMap' );
}

diag( "Testing Apache2::SiteMap $Apache2::SiteMap::VERSION, Perl $], $^X" );
