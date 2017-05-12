#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'BERT' ) || print "Bail out!\n";
}

diag( "Testing BERT $BERT::VERSION, Perl $], $^X" );
