#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 5 };

use AI::Categorizer;
ok 1; # Loaded

my $k = AI::Categorizer::KnowledgeSet->new();
ok $k;

my $c1 = AI::Categorizer::Category->by_name(name => 'one');
my $c2 = AI::Categorizer::Category->by_name(name => 'two');
ok $c1;
ok $c2;

$k = AI::Categorizer::KnowledgeSet->new(categories => [$c1, $c2]);
ok $k;
