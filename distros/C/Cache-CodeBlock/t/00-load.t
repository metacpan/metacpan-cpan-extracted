#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Cache::CodeBlock' ) || print "Bail out!\n";
}

diag( "Testing Cache::CodeBlock $Cache::CodeBlock::VERSION, Perl $], $^X" );
