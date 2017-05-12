#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::WindowSession' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::WindowSession $Dancer::Plugin::WindowSession::VERSION, Perl $], $^X" );
