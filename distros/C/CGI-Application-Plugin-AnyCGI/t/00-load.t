#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::AnyCGI' );
}

diag( "Testing CGI::Application::Plugin::AnyCGI $CGI::Application::Plugin::AnyCGI::VERSION, Perl $], $^X" );
