#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Template::Tenjin' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Template::Tenjin $Dancer::Template::Tenjin::VERSION, Perl $], $^X" );
