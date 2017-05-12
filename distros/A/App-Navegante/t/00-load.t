#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'App::Navegante' );
	use_ok( 'App::Navegante::CGI' );
}

#diag( "Testing App::Navegante $App::Navegante::VERSION, Perl $], $^X" );
#diag( "Testing App::Navegante::CGI $App::Navegante::CGI::VERSION, Perl $], $^X" );
