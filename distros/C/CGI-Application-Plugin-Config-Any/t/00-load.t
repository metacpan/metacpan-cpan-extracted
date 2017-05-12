#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Application::Plugin::Config::Any' );
}

diag( "Testing CGI::Application::Plugin::Config::Any $CGI::Application::Plugin::Config::Any::VERSION, Perl $], $^X" );
