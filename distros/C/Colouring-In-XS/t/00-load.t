#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Colouring::In::XS' ) || print "Bail out!\n";
}

diag( "Testing Colouring::In::XS $Colouring::In::XS::VERSION, Perl $], $^X" );
