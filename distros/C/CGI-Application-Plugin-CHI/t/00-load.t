#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::CHI' );
}

diag( "Testing CGI::Application::Plugin::CHI $CGI::Application::Plugin::CHI::VERSION, Perl $], $^X" );
