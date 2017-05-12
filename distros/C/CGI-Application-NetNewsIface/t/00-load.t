#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::NetNewsIface' );
}

diag( "Testing CGI::Application::NetNewsIface $CGI::Application::NetNewsIface::VERSION, Perl $], $^X" );
