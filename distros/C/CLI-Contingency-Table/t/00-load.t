#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CLI::Contingency::Table' ) || print "Bail out!\n";
}

diag( "Testing CLI::Contingency::Table $CLI::Contingency::Table::VERSION, Perl $], $^X" );
