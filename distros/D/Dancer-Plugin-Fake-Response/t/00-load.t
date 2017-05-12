#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Fake::Response' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Fake::Response $Dancer::Plugin::Fake::Response::VERSION, Perl $], $^X" );
