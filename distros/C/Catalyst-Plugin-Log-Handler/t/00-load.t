#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Log::Handler' );
}

diag( "Testing Catalyst::Plugin::Log::Handler $Catalyst::Plugin::Log::Handler::VERSION, Perl $], $^X" );
