#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Circle::Block' ) || print "Bail out!\n";
}

diag( "Testing Circle::Block $Circle::Block::VERSION, Perl $], $^X" );
