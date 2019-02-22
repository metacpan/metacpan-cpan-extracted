#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'C::Mlock' ) || print "Bail out!\n";
}

diag( "Testing C::Mlock $C::Mlock::VERSION, Perl $], $^X" );
