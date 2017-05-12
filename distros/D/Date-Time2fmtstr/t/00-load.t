#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Date::Time2fmtstr' ) || print "Bail out!\n";
}

diag( "Testing Date::Time2fmtstr $Date::Time2fmtstr::VERSION, Perl $], $^X" );
