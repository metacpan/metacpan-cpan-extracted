#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::Authentication::Driver::DBIC' );
}

diag( "Testing CGI::Application::Plugin::Authentication::Driver::DBIC $CGI::Application::Plugin::Authentication::Driver::DBIC::VERSION, Perl $], $^X" );
