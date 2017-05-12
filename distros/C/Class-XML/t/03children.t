#!/usr/bin/perl

use strict;
use Test::More;
use MyTest::TopNode;

use strict;
plan tests => 6;

# Tests here

my $xml = qq!<foo><stalk beans="3" /><stalk /></foo>!;

my $tree = MyTest::TopNode->new( xml => $xml);

isa_ok($tree, 'MyTest::TopNode', "Tree object");
can_ok($tree, 'stalk');

is ("${tree}", $xml, "Stringify tree");

my @stalk = $tree->stalk;

cmp_ok(@stalk, '==', 2, "Two child nodes");

my $new_stalk = MyTest::MultiChild->new({ beans => 6 });

unshift(@stalk, $new_stalk);

$tree->stalk(@stalk);

is ("${tree}", qq!<foo><stalk beans="6" /><stalk beans="3" /><stalk /></foo>!,
  "Node add ok");

splice(@stalk, 1, 1);

$tree->stalk(@stalk);

is ("${tree}", qq!<foo><stalk beans="6" /><stalk /></foo>!, "Node delete ok");
