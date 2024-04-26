#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Dumper::UnDumper' ) || print "Bail out!\n";
}

diag( "Testing Data::Dumper::UnDumper $Data::Dumper::UnDumper::VERSION, Perl $], $^X" );
