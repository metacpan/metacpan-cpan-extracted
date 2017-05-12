#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Birthday' ) || print "Bail out!\n";
}

diag( "Testing App::Birthday $App::Birthday::VERSION, Perl $], $^X" );
