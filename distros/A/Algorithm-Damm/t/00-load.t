#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok( 'Algorithm::Damm' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::Damm $Algorithm::Damm::VERSION, Perl $], $^X" );
