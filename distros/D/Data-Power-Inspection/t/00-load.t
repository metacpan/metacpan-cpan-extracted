#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Power::Inspection' ) || print "Bail out!\n";
}

diag( "Testing Data::Power::Inspection $Data::Power::Inspection::VERSION, Perl $], $^X" );
