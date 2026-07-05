#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Chorus::Expert' ) || print "Bail out!\n";
    use_ok( 'Chorus::Engine' ) || print "Bail out!\n";
    use_ok( 'Chorus::Frame' )  || print "Bail out!\n";
}

diag( "Testing Chorus::Expert Libs $Chorus::Expert::VERSION, Perl $], $^X" );
