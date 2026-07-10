#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
	use_ok('Algorithm::Classifier::IsolationForest')         || print "Bail out!\n";
	use_ok('Algorithm::Classifier::IsolationForest::Online') || print "Bail out!\n";
}

diag("Testing Algorithm::Classifier::IsolationForest $Algorithm::Classifier::IsolationForest::VERSION, Perl $], $^X");
