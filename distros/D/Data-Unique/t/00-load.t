#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Unique' ) || print "Bail out!\n";
}

diag( "Testing Data::Unique $Data::Unique::VERSION, Perl $], $^X" );
