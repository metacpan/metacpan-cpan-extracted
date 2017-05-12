#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DJabberd::Plugin::Ping' );
}

diag( "Testing DJabberd::Plugin::Ping $DJabberd::Plugin::Ping::VERSION, Perl $], $^X" );
