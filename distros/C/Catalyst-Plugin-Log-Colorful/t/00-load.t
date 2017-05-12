#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Log::Colorful' );
}

diag( "Testing Catalyst::Plugin::Log::Colorful $Catalyst::Plugin::Log::Colorful::VERSION, Perl $], $^X" );
