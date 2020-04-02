#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Caller::Reverse' ) || print "Bail out!\n";
}

diag( "Testing Caller::Reverse $Caller::Reverse::VERSION, Perl $], $^X" );
