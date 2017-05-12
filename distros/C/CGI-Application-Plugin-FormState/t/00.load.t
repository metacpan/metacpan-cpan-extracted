use Test::More tests => 1;

use CGI::Application;
BEGIN { @::ISA = qw(CGI::Application) };

BEGIN {
    use_ok( 'CGI::Application::Plugin::FormState' );
}

diag( "Testing CGI::Application::Plugin::FormState $CGI::Application::Plugin::FormState::VERSION" );
