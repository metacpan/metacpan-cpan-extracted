#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::List' );
}

diag( "Testing CGI::List $CGI::List::VERSION, Perl $], $^X" );
