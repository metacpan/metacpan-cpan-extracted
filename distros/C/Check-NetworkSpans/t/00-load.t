#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Check::NetworkSpans' ) || print "Bail out!\n";
}

diag( "Testing Check::NetworkSpans $Check::NetworkSpans::VERSION, Perl $], $^X" );
