#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
	use_ok('Algorithm::Classifier::NaiveBayes') || print "Bail out!\n";
}

diag("Testing Algorithm::Classifier::NaiveBayes $Algorithm::Classifier::NaiveBayes::VERSION, Perl $], $^X");
