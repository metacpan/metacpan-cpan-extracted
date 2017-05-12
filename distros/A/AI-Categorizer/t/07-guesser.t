#!/usr/bin/perl -w

#########################

use strict;
use Test;
BEGIN {
  require 't/common.pl';
  plan tests => 1 + num_setup_tests();
}

ok(1);

#########################

my ($learner, $docs) = set_up_tests(learner_class => 'AI::Categorizer::Learner::Guesser');
