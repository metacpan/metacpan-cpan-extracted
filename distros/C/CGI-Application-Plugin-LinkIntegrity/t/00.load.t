
use Test::More tests => 1;
use CGI::Application;

BEGIN {
    @::ISA = qw(CGI::Application);
}

BEGIN {
    use_ok( 'CGI::Application::Plugin::LinkIntegrity' );
}

diag( "Testing CGI::Application::Plugin::LinkIntegrity $CGI::Application::Plugin::LinkIntegrity::VERSION" );
