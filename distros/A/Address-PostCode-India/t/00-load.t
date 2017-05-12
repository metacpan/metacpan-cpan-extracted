#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Address::PostCode::India')        || print "Bail out!\n";
    use_ok('Address::PostCode::India::Place') || print "Bail out!\n";
}

diag( "Testing Address::PostCode::India $Address::PostCode::India::VERSION, Perl $], $^X" );
