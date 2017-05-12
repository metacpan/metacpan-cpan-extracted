#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Apache2::CondProxy' ) || print "Bail out!\n";
}

diag( "Testing Apache2::CondProxy $Apache2::CondProxy::VERSION, Perl $], $^X" );
