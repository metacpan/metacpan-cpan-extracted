#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Brocade::BSC' ) || print "Bail out!\n";
}

diag( "Testing Brocade::BSC $Brocade::BSC::VERSION, Perl $], $^X" );
