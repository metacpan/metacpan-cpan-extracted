#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CLI::LaTeX::Table' ) || print "Bail out!\n";
}

diag( "Testing CLI::LaTeX::Table $CLI::LaTeX::Table::VERSION, Perl $], $^X" );
