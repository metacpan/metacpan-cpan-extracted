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

use Data::Dumper;
use File::Temp 'tempfile';
use DBICx::TestDatabase;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $trees = $schema->resultset('MultiTree');
isa_ok($trees, 'DBIx::Class::ResultSet');

my $root = $trees->create({ id => 1, content => 'root' });
isa_ok($root, 'DBIx::Class::Row');

is($root->id, 1, 'root has correct ID');
is($root->content, 'root', 'root has correct content');
is($root->parent, undef, 'root has no parent');
is($root->root->id, $root->id, 'root field gets set automatically');
is($root->descendants->count, 0, 'no descendants, initially');
is($root->nodes->count, 1, 'nodes include self');

ok( $root->is_root,   'is_root()');
ok( $root->is_leaf,   'is_leaf()');
ok(!$root->is_branch, 'is_branch()');

my $auto_inc = 1;

# Create a test tree
my $test_tree = [
    [1,  1,  20, 'root', undef, 0],
    [2,  2,  13, 'A',    1,     1],
    [3,  3,   4, 'B',    2,     2],
    [4,  5,  10, 'C',    2,     2],
    [5,  11, 12, 'D',    2,     2],
    [6,  6,  7,  'E',    4,     3],
    [7,  8,  9,  'F',    4,     3],
    [8,  14, 19, 'G',    1,     1],
    [9,  15, 16, 'H',    8,     2],
    [10, 17, 18, 'I',    8,     2],
];

my ($success, $child, $parent);

$root = create_tree(1, $test_tree);

test_tree($root, "Initial Tree", $test_tree);

# Test the 'is_root' interface
my $is_root = $root->is_root;
is($is_root, 1, "Root is root");

# Test for descendants of leaf nodes
for my $id (3,6,7,5,9,10) {
    $parent = $schema->resultset('MultiTree')->find($id);
    # list context
    my @descendants = $parent->descendants;
    is(scalar @descendants, 0, "List - descendants of leaf node $id");
    # scalar context
    $child  = $parent->descendants;
    is($child, 0, "Scalar - descendants of leaf node $id");
}

# Test for descendants of branches
for my $test ([1,[2,3,4,6,7,5,8,9,10]],[2,[3,4,6,7,5]],[4,[6,7]],[8,[9,10]]) {
    my $parent_id    = $test->[0];
    my @descendants_ids= @{$test->[1]};
    # list context
    $parent         = $schema->resultset('MultiTree')->find($parent_id);
    is($parent->descendants->count, scalar(@descendants_ids), "Number of descendants for $parent_id");

    my @descendants    = $parent->descendants;
    my $index = 0;
    for my $child (@descendants) {
        is($child->id, $descendants_ids[$index++], "List - Child $index of $parent_id");
    }
    # scalar context
    $parent         = $schema->resultset('MultiTree')->find($parent_id);
    my $descendants    = $parent->descendants;
    $index = 0;
    while (my $child = $descendants->next) {
        is($child->id, $descendants_ids[$index++], "Scalar - Child $index of $parent_id");
    }
}

# Test for ancestors of root
# list context
$child          = $schema->resultset('MultiTree')->find(1);
my @ancestors   = $child->ancestors;
is(@ancestors, 0, "Scalar - ancestors of root node");

# scalar context
$child          = $schema->resultset('MultiTree')->find(1);
my $ancestors   = $child->ancestors;
is ($ancestors, 0, "List - ancestors of root node");

# Test for ancestors
for my $test ([2,[1]],[3,[2,1]],[4,[2,1]],[6,[4,2,1]],[7,[4,2,1]],[5,[2,1]],[9,[8,1]],[10,[8,1]],[8,[1]]) {
    my $child_id    = $test->[0];
    my @ancestor_ids= @{$test->[1]};
    # list context
    $child          = $schema->resultset('MultiTree')->find($child_id);
    my @ancestors   = $child->ancestors;
    my $index = 0;
    for my $ancestor (@ancestors) {
        is($ancestor->id, $ancestor_ids[$index++], "List - Ancestor $index of $child_id");
    }
    # scalar context
    $child          = $schema->resultset('MultiTree')->find($child_id);
    my $ancestors   = $child->ancestors;
    $index = 0;
    while (my $ancestor = $ancestors->next) {
        is($ancestor->id, $ancestor_ids[$index++], "Scalar - Ancestor $index of $child_id");
    }
}

done_testing();
exit;

#### insert tests ####
# Insert a left child of the root node
$root = create_tree($test_tree);
$root->prepend_child({
    parent_id   => 11,
    name        => 'left_child',
});


$child = $schema->resultset('MultiTree')->create({
    id              => 11,
    title           => 'left child',
});




$success = $root->insert_left_child($child);
ok($success, "Left child inserted to root");
test_tree("Left Child to Root",[
    [1,  1,  22, 'root'],
    [2,  4,  15, 'A'],
    [3,  5,   6, 'B'],
    [4,  7,  12, 'C'],
    [5,  13, 14, 'D'],
    [6,  8,  9,  'E'],
    [7,  10, 11, 'F'],
    [8,  16, 21, 'G'],
    [9,  17, 18, 'H'],
    [10, 19, 20, 'I'],
    [11,  2,  3, 'left child'],
]);


# Insert a left child of a leaf node
$root = create_tree($test_tree);
$child = $schema->resultset('MultiTree')->create({
    id              => 11,
    title           => 'left child',
});
($parent) = $schema->resultset('MultiTree')->search({id => 10,});
$success = $parent->insert_left_child($child);
ok($success, "Left child inserted to 10");
test_tree("Left Child to Leaf", [
    [1,  1,  22, 'root'],
    [2,  2,  13, 'A'],
    [3,  3,   4, 'B'],
    [4,  5,  10, 'C'],
    [5,  11, 12, 'D'],
    [6,  6,  7,  'E'],
    [7,  8,  9,  'F'],
    [8,  14, 21, 'G'],
    [9,  15, 16, 'H'],
    [10, 17, 20, 'I'],
    [11, 18, 19, 'left child'],
]);

# Insert a left child of a non leaf node
$root = create_tree($test_tree);
$child = $schema->resultset('MultiTree')->create({
    id              => 11,
    title           => 'left child',
});
($parent) = $schema->resultset('MultiTree')->search({id => 8,});
$success = $parent->insert_left_child($child);
ok($success, "Left child inserted to 8");
test_tree("Left Child to non Leaf",[
    [1,  1,  22, 'root'],
    [2,  2,  13, 'A'],
    [3,  3,   4, 'B'],
    [4,  5,  10, 'C'],
    [5,  11, 12, 'D'],
    [6,  6,  7,  'E'],
    [7,  8,  9,  'F'],
    [8,  14, 21, 'G'],
    [9,  17, 18, 'H'],
    [10, 19, 20, 'I'],
    [11, 15, 16, 'left child'],
]);

#### insert_right_child tests ####
# Insert a right child of the root node
$root = create_tree($test_tree);
$child = $schema->resultset('MultiTree')->create({
    id              => 11,
    title           => 'right child',
});
$success = $root->insert_right_child($child);
ok($success, "Right child inserted to root");
test_tree("Right Child to Root",[
    [1,  1,  22, 'root'],
    [2,  2,  13, 'A'],
    [3,  3,   4, 'B'],
    [4,  5,  10, 'C'],
    [5,  11, 12, 'D'],
    [6,  6,  7,  'E'],
    [7,  8,  9,  'F'],
    [8,  14, 19, 'G'],
    [9,  15, 16, 'H'],
    [10, 17, 18, 'I'],
    [11, 20, 21, 'right child'],
]);

# Insert a right child of a leaf node
$root = create_tree($test_tree);
$child = $schema->resultset('MultiTree')->create({
    id              => 11,
    title           => 'right child',
});
($parent) = $schema->resultset('MultiTree')->search({id => 9,});
$success = $parent->insert_right_child($child);
ok($success, "Right child inserted to 9");
test_tree("Right Child to Leaf",[
    [1,  1,  22, 'root'],
    [2,  2,  13, 'A'],
    [3,  3,   4, 'B'],
    [4,  5,  10, 'C'],
    [5,  11, 12, 'D'],
    [6,  6,  7,  'E'],
    [7,  8,  9,  'F'],
    [8,  14, 21, 'G'],
    [9,  15, 18, 'H'],
    [10, 19, 20, 'I'],
    [11, 16, 17, 'right child'],
]);

# Insert a right child to a non leaf node
$root = create_tree($test_tree);
$child = $schema->resultset('MultiTree')->create({
    id              => 11,
    title           => 'right child',
});
($parent) = $schema->resultset('MultiTree')->search({id => 8,});
$success = $parent->insert_right_child($child);
ok($success, "Right child inserted to 8");
test_tree("Right Child to non Leaf",[
    [1,  1,  22, 'root'],
    [2,  2,  13, 'A'],
    [3,  3,   4, 'B'],
    [4,  5,  10, 'C'],
    [5,  11, 12, 'D'],
    [6,  6,  7,  'E'],
    [7,  8,  9,  'F'],
    [8,  14, 21, 'G'],
    [9,  15, 16, 'H'],
    [10, 17, 18, 'I'],
    [11, 19, 20, 'right child'],
]);

# Test for ancestors
$root = create_tree($test_tree);
for my $test ([2,1],[3,2],[4,2],[6,4],[7,4],[5,2],[9,8],[10,8],[8,1]) {
    my $child_id    = $test->[0];
    my $parent_id   = $test->[1];
    my $child       = $schema->resultset('MultiTree')->find($child_id);
    my $parent      = $child->parent;
    is($parent->id, $parent_id, "Parent of $child_id is $parent_id");
}

# Test for ancestors
$root = create_tree($test_tree);
for my $test ([2,[1]],[3,[1,2]],[4,[1,2]],[6,[1,2,4]],[7,[1,2,4]],[5,[1,2]],[9,[1,8]],[10,[1,8]],[8,[1]]) {
    my $child_id    = $test->[0];
    my @ancestor_ids= @{$test->[1]};
    # list context
    $child          = $schema->resultset('MultiTree')->find($child_id);
    my @ancestors   = $child->ancestors;
    my $index = 0;
    for my $ancestor (@ancestors) {
        is($ancestor->id, $ancestor_ids[$index++], "List - Ancestor $index of $child_id");
    }
    # scalar context
    $child          = $schema->resultset('MultiTree')->find($child_id);
    my $ancestors   = $child->ancestors;
    $index = 0;
    while (my $ancestor = $ancestors->next) {
        is($ancestor->id, $ancestor_ids[$index++], "Scalar - Ancestor $index of $child_id");
    }
}



#============== subroutines ====================

# Test an array of nodes, each contains an array of id, lft and rgt
sub test_tree {
    my ( $root, $test_name, $array_ref) = @_;

    # left and right extents must be unique
    my @extents = [];
    for my $node (@$array_ref) {
        my ($id, $left, $right, $content) = @$node;
        my $node = $schema->resultset('MultiTree')->find($id);
        ok($node, "$test_name: Node $id found");
        is($node->lft, $left, "$test_name: Left Extent is $left");
        is($node->rgt, $right, "$test_name: Right Extent is $right");
        is($node->content, $content, "$test_name: Name is $content");
    }
}

# Create a complete tree
sub create_tree {
    my ($root_id, $array_ref) = @_;

    $auto_inc = $root->id + 1;
    $schema->resultset('MultiTree')->delete;

    for my $node (@$array_ref) {
        my ($id, $left, $right, $content, $parent, $level) = @$node;
        my $node = $schema->resultset('MultiTree')->create({
            id          => $id,
            root_id     => $root->id,
            lft         => $left,
            rgt         => $right,
            content     => $content,
            level       => $level,
        });
        if ($id >= $auto_inc) {
            $auto_inc = $id + 1;
        }
    }
    my $root = $schema->resultset('MultiTree')->find($root_id);
    return $root;
}


