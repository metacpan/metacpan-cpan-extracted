#!/usr/bin/perl

use Test;
BEGIN { plan tests => 4 }

use AI::DecisionTree::Instance;
ok(1);

my $x = 0;
{
  local *{"AI::DecisionTree::Instance::DESTROY"} = sub { $x = 1 };
  {
    my $i = new AI::DecisionTree::Instance([3,4], 4, "foo");
    ok $x, 0;
  }
  ok $x, 1;
}
ok $x, 1;
