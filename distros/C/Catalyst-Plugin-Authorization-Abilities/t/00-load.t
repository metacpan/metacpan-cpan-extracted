#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Authorization::Abilities' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::Authorization::Abilities $Catalyst::Plugin::Authorization::Abilities::VERSION, Perl $], $^X" );
