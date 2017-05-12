#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'AnyEvent::HTTPD' );
}

diag( "Testing AnyEvent::HTTPD $AnyEvent::HTTPD::VERSION, Perl $], $^X" );
