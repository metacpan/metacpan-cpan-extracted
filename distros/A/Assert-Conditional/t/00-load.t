#!perl -T
use v5.10;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok("Assert::Conditional") || print "Bail out!\n";
}

diag sprintf "Testing Assert::Conditional %s using perl v%vd in %s", Assert::Conditional->VERSION, $^V, $^X;
