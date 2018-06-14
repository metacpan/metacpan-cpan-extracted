#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CLI::Table::Key::Finder' ) || print "Bail out!\n";
}

diag( "Testing CLI::Table::Key::Finder $CLI::Table::Key::Finder::VERSION, Perl $], $^X" );
