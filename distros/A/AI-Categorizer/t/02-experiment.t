#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
BEGIN { plan tests => 14 };

use AI::Categorizer;
use AI::Categorizer::Experiment;

ok(1);

my $all_categories = [qw(sports politics finance world)];

{
  my $e = new AI::Categorizer::Experiment(categories => $all_categories);
  ok $e;
  
  $e->add_result(['sports','finance'], ['sports']);
  ok $e->micro_recall, 1, "micro recall";
  ok $e->micro_precision, 0.5, "micro precision";
  ok $e->micro_F1, 2/3, "micro F1";
}

{
  my $e = new AI::Categorizer::Experiment(categories => $all_categories);
  $e->add_result(['sports','finance'], ['politics']);
  ok $e->micro_recall, 0, "micro recall";
  ok $e->micro_precision, 0, "micro precision";
  ok $e->micro_F1, 0, "micro F1";
}

{
  my $e = new AI::Categorizer::Experiment(categories => $all_categories);
  
  $e->add_result(['sports','finance'], ['sports']);
  $e->add_result(['sports','finance'], ['politics']);

  ok $e->micro_recall, 0.5, "micro recall";
  ok $e->micro_precision, 0.25, "micro precision";
  ok $e->micro_F1, 1/3, "micro F1";

  ok $e->macro_recall, 0.75, "macro recall";
  ok $e->macro_precision, 0.375, "macro precision";
  ok $e->macro_F1, 5/12, "macro F1";
}
