#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CLI::Numbers::Hack' ) || print "Bail out!\n";
}

diag( "Testing CLI::Numbers::Hack $CLI::Numbers::Hack::VERSION, Perl $], $^X" );
