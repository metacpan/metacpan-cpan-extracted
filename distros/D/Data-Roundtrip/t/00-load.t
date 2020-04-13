#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Roundtrip' ) || print "Bail out!\n";
}

diag( "Testing Data::Roundtrip $Data::Roundtrip::VERSION, Perl $], $^X" );
