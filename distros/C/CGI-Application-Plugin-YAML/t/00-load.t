#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::YAML' );
}

diag( "Testing CGI::Application::Plugin::YAML $CGI::Application::Plugin::YAML::VERSION, Perl $], $^X" );
