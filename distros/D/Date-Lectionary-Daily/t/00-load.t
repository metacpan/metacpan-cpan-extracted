#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Date::Lectionary::Daily')       || print "Bail out!\n";
}

diag("Testing Date::Lectionary::Daily $Date::Lectionary::Daily::VERSION, Perl $], $^X");
