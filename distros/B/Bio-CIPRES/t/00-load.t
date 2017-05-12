#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bio::CIPRES' ) || print "Bail out!\n";
}

diag( "Testing Bio::CIPRES $Bio::CIPRES::VERSION, Perl $], $^X" );
