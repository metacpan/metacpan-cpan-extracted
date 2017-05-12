#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::TimeRequests' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::TimeRequests $Dancer::Plugin::TimeRequests::VERSION, Perl $], $^X" );
