#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
BEGIN {
  require 't/common.pl';
  plan tests => 5 + 2 * num_standard_tests();
}

ok(1);

#########################

# There are only 4 test documents, so use k=2
perform_standard_tests(learner_class => 'AI::Categorizer::Learner::KNN', k_value => 2);
perform_standard_tests(learner_class => 'AI::Categorizer::Learner::KNN', k_value => 2, knn_weighting => 'uniform');

my $q = AI::Categorizer::Learner::KNN::Queue->new(size => 3);

$q->add(five => 5);
$q->add(four => 4);
$q->add(one => 1);
$q->add(ten => 10);
$q->add(three => 3);
$q->add(eleven => 11);

my $entries = $q->entries;
ok @{$entries}, 3;
ok $entries->[0]{score}, 5;
ok $entries->[1]{score}, 10;
ok $entries->[2]{score}, 11;
