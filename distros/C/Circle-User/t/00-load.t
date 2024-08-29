#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Circle::User' ) || print "Bail out!\n";
}

diag( "Testing Circle::User $Circle::User::VERSION, Perl $], $^X" );
