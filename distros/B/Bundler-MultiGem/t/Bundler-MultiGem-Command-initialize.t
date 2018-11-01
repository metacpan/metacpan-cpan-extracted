#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Bundler::MultiGem::Command::initialize' ) || print "Bail out!\n";
}

diag( "Testing Bundler::MultiGem::Command::initialize, Perl $], $^X" );