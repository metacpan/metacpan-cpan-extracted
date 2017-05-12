#!/usr/bin/env perl
#
# $Id: $
# $Revision: $
# $Author: $
# $Source:  $
#
# $Log: $
#
use strict;
use warnings;
use Test::More;
use DBICx::TestDatabase;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $trees = $schema->resultset('MultiTree');
isa_ok($trees, 'DBIx::Class::ResultSet');

my $tree1 = $trees->create({ content => 'tree1 root', root_id => 10});
my $tree2 = $trees->create({ content => 'tree2 root', root_id => 20});

is($tree1->ancestors->count, 0, "Root has no ancestors");
is($tree2->parent, undef, "Root has no parent");

# Add children to tree1
my $child1_0 = $tree1->create_rightmost_child({ content => 'child1_0'});
my $child1_1 = $child1_0->create_right_sibling({ content => 'child1-1'});
my $child1_2 = $child1_0->create_right_sibling({ content => 'child1-2'});
my $child1_3 = $child1_0->create_right_sibling({ content => 'child1-3'});

my $g_child10_1     = $child1_0->add_to_children({ content => 'g_child10_1'});
my $g_child10_2     = $child1_0->add_to_children({ content => 'g_child10_2'});
my $gg_child102_1   = $g_child10_2->add_to_children({ content => 'g_child102_1'});

$tree1->discard_changes;
$child1_0->discard_changes;
$child1_1->discard_changes;
$child1_2->discard_changes;
$child1_3->discard_changes;
$g_child10_1->discard_changes;
$g_child10_2->discard_changes;
$gg_child102_1->discard_changes;

is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_0, $g_child10_1, $g_child10_2, $gg_child102_1, $child1_3, $child1_2, $child1_1],
    'Tree 1 is organised correctly.',
);

#Test deleting a leaf node
$child1_2->delete;
$tree1->discard_changes;
$child1_0->discard_changes;
$child1_1->discard_changes;
$child1_3->discard_changes;
$g_child10_1->discard_changes;
$g_child10_2->discard_changes;
$gg_child102_1->discard_changes;

is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_0, $g_child10_1, $g_child10_2, $gg_child102_1, $child1_3, $child1_1],
    'Tree 1 is organised correctly after deletion.',
);

# Test deleting a branch
$g_child10_2->delete;
$tree1->discard_changes;
$child1_0->discard_changes;
$child1_1->discard_changes;
$child1_3->discard_changes;
$g_child10_1->discard_changes;

is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_0, $g_child10_1, $child1_3, $child1_1],
    'Tree 1 is organised correctly after deletion.',
);

# Delete remaining nodes except root
$child1_0->delete;
$child1_1->delete;
$child1_3->delete;

is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1],
    'Tree 1 is organised correctly after deletion of all nodes.',
);

# Delete the root
$tree1->delete;

my $tree1_count = $trees->search({root_id => 10})->count;
is($tree1_count, 0, "There are no more nodes in tree1");

my $tree2_count = $trees->search({root_id => 20})->count;
is($tree2_count, 1, "Tree2 still exists");

done_testing();
exit;

