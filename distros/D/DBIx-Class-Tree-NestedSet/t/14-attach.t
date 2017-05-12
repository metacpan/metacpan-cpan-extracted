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
use Test::Exception;
use DBICx::TestDatabase;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

use TestTree;

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $test_tree = TestTree->new({schema => $schema});

my $trees = $schema->resultset('MultiTree');
isa_ok($trees, 'DBIx::Class::ResultSet');

# Create the tree
my $tree1 = $trees->create({ content => '1 tree root', root_id => 10});

my $child1_1 = $tree1->add_to_children({ content => '1 child 1' });
my $child1_2 = $tree1->add_to_children({ content => '1 child 2' });
my $child1_3 = $tree1->add_to_children({ content => '1 child 3' });
my $child1_4 = $tree1->add_to_children({ content => '1 child 4' });

my $gchild1_1 = $child1_2->add_to_children({ content => '1 g-child 1' });
my $gchild1_2 = $child1_2->add_to_children({ content => '1 g-child 2' });
my $gchild1_3 = $child1_4->add_to_children({ content => '1 g-child 3' });
my $gchild1_4 = $child1_4->add_to_children({ content => '1 g-child 4' });

my $ggchild1 = $gchild1_2->add_to_children({ content => '1 gg-child 1' });

# Check that the test tree is constructed correctly

is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_1, $child1_2, $gchild1_1, $gchild1_2, $ggchild1, $child1_3, $child1_4, $gchild1_3, $gchild1_4],
    'Test Tree is organised correctly.',
);
$tree1->discard_changes;
$test_tree->structure($tree1,"Initial Tree");

# Promote ggchild1 to become a sibling of descendant
$child1_2->discard_changes;
$ggchild1->discard_changes;
$child1_2->attach_right_sibling($ggchild1);
$tree1->discard_changes;
$test_tree->structure($tree1,"After ggchild becomes child of root");
my @children = $tree1->children;
is_deeply(
    [map { $_->id} @children],
    [map { $_->id} $child1_1, $child1_2, $ggchild1, $child1_3, $child1_4 ],
    'Test if ggchild has become rightmost sibling of child1_2',
);

$tree1->discard_changes;
$gchild1_2->discard_changes;
$ggchild1->discard_changes;
$gchild1_2->attach_rightmost_child($ggchild1);

$gchild1_2->discard_changes;
@children = $gchild1_2->children;
is_deeply(
    [map { $_->id} @children],
    [map { $_->id} $ggchild1, ],
    'Test if ggchild has been put back',
);
$tree1->discard_changes;
$test_tree->structure($tree1, "after moving ggchild back");

done_testing();
exit;

