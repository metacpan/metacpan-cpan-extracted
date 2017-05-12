#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DJabberd::Plugin::EntityTime' );
}

diag( "Testing DJabberd::Plugin::EntityTime $DJabberd::Plugin::EntityTime::VERSION, Perl $], $^X" );
