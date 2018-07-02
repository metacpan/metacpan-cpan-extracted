#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CLI::TextLines::Utils' ) || print "Bail out!\n";
}

diag( "Testing CLI::TextLines::Utils $CLI::TextLines::Utils::VERSION, Perl $], $^X" );
