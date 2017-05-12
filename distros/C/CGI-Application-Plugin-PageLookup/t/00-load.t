#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'CGI::Application::Plugin::PageLookup' );
    use_ok( 'CGI::Application::Plugin::PageLookup::Href' );
    use_ok( 'CGI::Application::Plugin::PageLookup::Loop' );
    use_ok( 'CGI::Application::Plugin::PageLookup::Value' );
    use_ok( 'CGI::Application::Plugin::PageLookup::Menu' );
}

diag( "Testing CGI::Application::Plugin::PageLookup $CGI::Application::Plugin::PageLookup::VERSION, Perl $], $^X" );
