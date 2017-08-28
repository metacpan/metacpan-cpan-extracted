#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Netflow' ) || print "Bail out!\n";
}

diag( "Testing Data::Netflow $Data::Netflow::VERSION, Perl $], $^X" );
