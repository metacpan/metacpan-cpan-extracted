#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::csv2tsv' ) || print "Bail out!\n";
}

diag( "Testing App::csv2tsv $App::csv2tsv::VERSION, Perl $], $^X" );
