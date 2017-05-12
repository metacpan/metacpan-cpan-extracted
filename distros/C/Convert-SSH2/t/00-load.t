#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Convert::SSH2' ) || print "Bail out!\n";
}

diag( "Testing Convert::SSH2 $Convert::SSH2::VERSION, Perl $], $^X" );
