#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

#plan tests => 2;

BEGIN {
    use_ok( 'AI::Embedding' ) || print "Bail out!\n";
}

diag( "Testing AI::Embedding $AI::Embedding::VERSION, Perl $], $^X" );
