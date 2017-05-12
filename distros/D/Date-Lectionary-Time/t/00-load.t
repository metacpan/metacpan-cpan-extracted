#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Date::Lectionary::Time' ) || print "Bail out!\n";
}

diag( "Testing Date::Lectionary::Time $Date::Lectionary::Time::VERSION, Perl $], $^X" );
