#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Date::Utility') || print "Bail out!\n";
}

diag("Testing Date::Utility $Date::Utility::VERSION, Perl $], $^X");
