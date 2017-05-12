use Test::More tests => 4;

BEGIN {
use_ok( 'CGI::Application::Plugin::DBIProfile' );
use_ok( 'CGI::Application::Plugin::DBIProfile::Driver' );
use_ok( 'CGI::Application::Plugin::DBIProfile::Data' );
use_ok( 'CGI::Application::Plugin::DBIProfile::Graph::HTML' );
}

diag( "Testing CGI::Application::Plugin::DBIProfile $CGI::Application::Plugin::DBIProfile::VERSION, Perl 5.008006, /usr/local/bin/perl" );
