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

$tree1->discard_changes;
$child1_1->discard_changes;
$child1_2->discard_changes;
$child1_3->discard_changes;
$child1_4->discard_changes;
my (@children, $sibling, @siblings, $siblings_rs, @ids);

goto NEXT;
NEXT:

# Check that the test tree is constructed correctly
is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_1, $child1_2, $gchild1_1, $gchild1_2, $ggchild1, $child1_3, $child1_4, $gchild1_3, $gchild1_4],
    'Test Tree is organised correctly.',
);
$test_tree->structure($tree1,"Initial Tree");
# siblings
$siblings_rs = $tree1->siblings;
is($siblings_rs, undef, "Root has no siblings");

@siblings = $child1_3->siblings;
is(scalar @siblings, 3, "Scalar - siblings - correct number");
is_deeply(
    [map {$_->id} @siblings],
    [map {$_->id} $child1_1, $child1_2, $child1_4],
    'List - siblings - correct ids',
);
$siblings_rs = $child1_3->siblings;
while (my $sibling = $siblings_rs->next) {
    push @ids, $sibling->id;
}
is_deeply(
    [@ids],
    [map {$_->id} $child1_1, $child1_2, $child1_4],
    'Scalar - siblings - correct ids',
);

# left siblings
@siblings = $child1_3->left_siblings;
is(scalar @siblings, 2, "Scalar - left_siblings - correct number");
is_deeply(
    [map {$_->id} @siblings],
    [map {$_->id} $child1_1, $child1_2],
    'List - left_siblings - correct ids',
);
$siblings_rs = $child1_3->left_siblings;
undef @ids;
while (my $sibling = $siblings_rs->next) {
    push @ids, $sibling->id;
}
is_deeply(
    [@ids],
    [map {$_->id} $child1_1, $child1_2],
    'Scalar - left_siblings - correct ids',
);
$siblings_rs = $child1_1->left_siblings;
is($siblings_rs->next, undef, "Scalar - left_siblings - no left siblings");

# right siblings
@siblings = $child1_3->right_siblings;
is(scalar @siblings, 1, "Scalar - right_siblings - correct number");
is_deeply(
    [map {$_->id} @siblings],
    [map {$_->id} $child1_4],
    'List - right_siblings - correct ids',
);
$siblings_rs = $child1_3->right_siblings;
undef @ids;
while (my $sibling = $siblings_rs->next) {
    push @ids, $sibling->id;
}
is_deeply(
    [@ids],
    [map {$_->id} $child1_4],
    'Scalar - right_siblings - correct ids',
);
$siblings_rs = $child1_4->right_siblings;
is($siblings_rs->next, undef, "Scalar - right_siblings - none expected");

# previous sibling
$sibling = $child1_4->left_sibling;
is($sibling->id, $child1_3->id, "Left Sibling - correct ID");

$sibling = $child1_1->left_sibling;
is($sibling, undef, "Left Sibling - leftmost child");

# next sibling
$sibling = $child1_2->right_sibling;
is($sibling->id, $child1_3->id, "Right Sibling - correct ID");

$sibling = $child1_4->right_sibling;
is($sibling, undef, "Right Sibling - rightmost child");

# first sibling
$sibling = $child1_4->first_sibling;
is($sibling->id, $child1_1->id, "First Sibling - correct ID");

$sibling = $child1_1->first_sibling;
is($sibling, undef, "First Sibling - leftmost child");

# last sibling
$sibling = $child1_2->last_sibling;
is($sibling->id, $child1_4->id, "Last Sibling - correct ID");

$sibling = $child1_4->last_sibling;
is($sibling, undef, "Last Sibling - rightmost child");

$test_tree->structure($tree1, "Initial Tree 2");
#### move operations ####
# move left
$sibling = $child1_1->move_left;
is($sibling, undef, "Should not be able to move leftmost child left");
$test_tree->structure($tree1, "after attempt to move leftmost child left");

$tree1->discard_changes;
$sibling = $child1_4->move_left;
is($sibling->id, $child1_3->id, "Can move rightmost child left");
$tree1->discard_changes;
$test_tree->structure($tree1, "after move rightmost child left");
@children = $tree1->children;
is_deeply(
    [map {$_->id} @children],
    [map {$_->id} $child1_1, $child1_2, $child1_4, $child1_3],
    'children after move rightmost child left',
);

$tree1->discard_changes;
$child1_4->discard_changes;
$sibling = $child1_4->move_right;
is($sibling->id, $child1_3->id, "Can move child back again");
$tree1->discard_changes;
$test_tree->structure($tree1, "after move child back again");
@children = $tree1->children;
is_deeply(
    [map {$_->id} @children],
    [map {$_->id} $child1_1, $child1_2, $child1_3, $child1_4],
    'children after move child back again',
);

# move right
$tree1->discard_changes;
$child1_4->discard_changes;
$sibling = $child1_4->move_right;
is($sibling, undef, "Should not be able to move rightmost child right");
$tree1->discard_changes;
$test_tree->structure($tree1, "after attempt to move rightmost child right");
@children = $tree1->children;
is_deeply(
    [map {$_->id} @children],
    [map {$_->id} $child1_1, $child1_2, $child1_3, $child1_4],
    'children after move child back again',
);

# move leftmost
$tree1->discard_changes;
$sibling = $child1_1->move_leftmost;
is($sibling, undef, "Should not be able to move leftmost child leftmost");
$test_tree->structure($tree1, "after attempt to move leftmost child leftmost");

$tree1->discard_changes;
$child1_3->discard_changes;
$sibling = $child1_3->move_leftmost;
is($sibling->id, $child1_1->id, "Can move child leftmost");
$tree1->discard_changes;
$test_tree->structure($tree1, "after move child leftmost");
@children = $tree1->children;
is_deeply(
    [map {$_->id} @children],
    [map {$_->id} $child1_3, $child1_1, $child1_2, $child1_4],
    'children after move rightmost child left',
);

# move rightmost
$tree1->discard_changes;
$child1_4->discard_changes;
$sibling = $child1_4->move_rightmost;
is($sibling, undef, "Should not be able to move rightmost child rightmost");
$tree1->discard_changes;
$test_tree->structure($tree1, "after attempt to move rightmost child rightmost");

$tree1->discard_changes;
$child1_3->discard_changes;
$sibling = $child1_3->move_rightmost;
is($sibling->id, $child1_4->id, "Can move node rightmost");
$tree1->discard_changes;
$test_tree->structure($tree1, "after move node rightmost");
@children = $tree1->children;
is_deeply(
    [map {$_->id} @children],
    [map {$_->id} $child1_1, $child1_2, $child1_4, $child1_3],
    'children after move rightmost child left',
);

done_testing();
exit;

