#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::CGI' );
}

diag( "Testing Class::CGI $Class::CGI::VERSION, Perl $], $^X" );
