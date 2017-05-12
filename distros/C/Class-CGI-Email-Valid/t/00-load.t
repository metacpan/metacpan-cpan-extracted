#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::CGI::Email::Valid' );
}

diag( "Testing Class::CGI::Email::Valid $Class::CGI::Email::Valid::VERSION, Perl $], $^X" );
