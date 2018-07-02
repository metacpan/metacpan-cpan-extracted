#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CLI::KeyValue::Hack' ) || print "Bail out!\n";
}

diag( "Testing CLI::KeyValue::Hack $CLI::KeyValue::Hack::VERSION, Perl $], $^X" );
