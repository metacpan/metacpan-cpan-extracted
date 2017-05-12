#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Date::Fmtstr2time' ) || print "Bail out!\n";
}

diag( "Testing Date::Fmtstr2time $Date::Fmtstr2time::VERSION, Perl $], $^X" );
