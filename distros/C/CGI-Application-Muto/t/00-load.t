#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Application::Muto' ) || print "Bail out!
";
}

diag( "Testing CGI::Application::Muto $CGI::Application::Muto::VERSION, Perl $], $^X" );
