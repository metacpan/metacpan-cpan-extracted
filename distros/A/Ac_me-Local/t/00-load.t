#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ac_me::Local' ) || print "Bail out!\n";
}

diag( "Testing Ac_me::Local $Ac_me::Local::VERSION, Perl $], $^X" );
