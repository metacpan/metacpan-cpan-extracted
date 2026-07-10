#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
	use_ok('Algorithm::ToNumberMunger') || print "Bail out!\n";
}

diag("Testing Algorithm::ToNumberMunger $Algorithm::ToNumberMunger::VERSION, Perl $], $^X");
