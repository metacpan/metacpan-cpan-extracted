#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
BEGIN {
  require 't/common.pl';
  need_module('AI::DecisionTree 0.06');
  plan tests => 1 + num_standard_tests();
}

ok(1);

#########################

perform_standard_tests(learner_class => 'AI::Categorizer::Learner::DecisionTree');
