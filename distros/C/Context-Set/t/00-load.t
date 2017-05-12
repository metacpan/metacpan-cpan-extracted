#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Context::Set' ) || print "Bail out!\n";
}

diag( "Testing Context $Context::Set::VERSION, Perl $], $^X" );
