#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::Authentication::Driver::CDBI' );
}

diag( "Testing CGI::Application::Plugin::Authentication::Driver::CDBI $CGI::Application::Plugin::Authentication::Driver::CDBI::VERSION, Perl $], $^X" );
