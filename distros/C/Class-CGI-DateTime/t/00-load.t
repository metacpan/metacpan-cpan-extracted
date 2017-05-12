#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::CGI::DateTime' );
}

diag( "Testing Class::CGI::DateTime $Class::CGI::DateTime::VERSION, Perl $], $^X" );
