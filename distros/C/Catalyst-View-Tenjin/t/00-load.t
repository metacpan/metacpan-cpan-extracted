#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Catalyst::View::Tenjin' ) || print "Wrapper bad!\n";
	use_ok( 'Catalyst::Helper::View::Tenjin' ) || print "Helper bad!\n";

}

diag( "Testing Catalyst::View::Tenjin $Catalyst::View::Tenjin::VERSION, Perl $], $^X" );
