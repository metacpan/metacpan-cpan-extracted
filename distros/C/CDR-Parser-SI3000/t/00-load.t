#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CDR::Parser::SI3000' ) || print "Bail out!\n";
}

diag( "Testing CDR::Parser::SI3000 $CDR::Parser::SI3000::VERSION, Perl $], $^X" );
