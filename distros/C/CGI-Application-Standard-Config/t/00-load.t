#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Standard::Config' );
}

diag( "Testing CGI::Application::Standard::Config $CGI::Application::Standard::Config::VERSION, Perl $], $^X" );
