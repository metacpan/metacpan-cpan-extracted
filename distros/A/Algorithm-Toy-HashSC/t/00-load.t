#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Algorithm::Toy::HashSC' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::Toy::HashSC $Algorithm::Toy::HashSC::VERSION, Perl $], $^X" );
