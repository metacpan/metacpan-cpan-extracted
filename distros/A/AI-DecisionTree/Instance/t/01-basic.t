#!/usr/bin/perl

use Test;
BEGIN { plan tests => 7 }

use AI::DecisionTree::Instance;
ok(1);

my $i = AI::DecisionTree::Instance->new([1, 2], 0, "foo");
ok $i->value_int(0), 1;
ok $i->value_int(1), 2;
ok $i->result_int, 0;

$i->set_value(0, 3);
ok $i->value_int(0), 3;

$i = new AI::DecisionTree::Instance([4], 2, "bar");
ok $i->value_int(0), 4;
ok $i->result_int, 2;

