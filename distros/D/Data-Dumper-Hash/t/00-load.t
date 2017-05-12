#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Dumper::Hash' ) || print "Bail out!\n";
}

diag( "Testing Data::Dumper::Hash $Data::Dumper::Hash::VERSION, Perl $], $^X" );
