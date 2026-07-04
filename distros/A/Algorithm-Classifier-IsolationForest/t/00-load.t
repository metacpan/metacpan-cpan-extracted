#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
	use_ok('Algorithm::Classifier::IsolationForest') || print "Bail out!\n";
}

diag("Testing Algorithm::Classifier::IsolationForest $Algorithm::Classifier::IsolationForest::VERSION, Perl $], $^X");
