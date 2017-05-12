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

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $trees = $schema->resultset('MultiTree');
isa_ok($trees, 'DBIx::Class::ResultSet');

# Create the tree
my $tree = $trees->create({ content => '1 tree root', root_id => 10});

my $child1 = $tree->add_to_children({ content => '1 child 1' });
my $child2 = $tree->add_to_children({ content => '1 child 2' });
my $child3 = $tree->add_to_children({ content => '1 child 3' });
my $child4 = $tree->add_to_children({ content => '1 child 4' });

my $gchild1 = $child2->add_to_children({ content => '1 g-child 1' });
my $gchild2 = $child2->add_to_children({ content => '1 g-child 2' });
my $gchild3 = $child4->add_to_children({ content => '1 g-child 3' });
my $gchild4 = $child4->add_to_children({ content => '1 g-child 4' });

my $ggchild = $gchild2->add_to_children({ content => '1 gg-child 1' });

# Check that the test tree is constructed correctly

is_deeply(
    [map { $_->id} $tree->nodes],
    [map { $_->id} $tree, $child1, $child2, $gchild1, $gchild2, $ggchild, $child3, $child4, $gchild3, $gchild4],
    'Test Tree is organised correctly.',
);

$child2->discard_changes;
$child2->_move_to_end;
is_deeply(
    [map { $_->id} $tree->nodes],
    [map { $_->id} $tree, $child1, $child3, $child4, $gchild3, $gchild4, $child2, $gchild1, $gchild2, $ggchild],
    'Tree is organised correctly after move_to_end',
);

# Try moving it to the right again
$child2->discard_changes;
$child2->_move_to_end;
is_deeply(
    [map { $_->id} $tree->nodes],
    [map { $_->id} $tree, $child1, $child3, $child4, $gchild3, $gchild4, $child2, $gchild1, $gchild2, $ggchild],
    'Tree is organised correctly after move_to_end 2',
);
# Move a leaf node to the right
$ggchild->discard_changes;
$ggchild->_move_to_end;
is_deeply(
    [map { $_->id} $tree->nodes],
    [map { $_->id} $tree, $child1, $child3, $child4, $gchild3, $gchild4, $child2, $gchild1, $gchild2, $ggchild],
    'Tree is organised correctly after move_to_end ggchild',
);
$tree->discard_changes;
is($ggchild->level, 1, "GG Child is now a child of root");
is($ggchild->rgt, $tree->rgt - 1, "GG Child is now a child of root with right rgt");

# Move leftmost child to the right
$child1->discard_changes;
$child1->_move_to_end;
is_deeply(
    [map { $_->id} $tree->nodes],
    [map { $_->id} $tree, $child3, $child4, $gchild3, $gchild4, $child2, $gchild1, $gchild2, $ggchild, $child1, ],
    'Tree is organised correctly after move_to_end ggchild',
);

# Create another test tree
my $tree2 = $trees->create({ content => '2 tree root', root_id => 20});

my $child2_1 = $tree2->add_to_children({ content => '2 child 1' });
my $child2_2 = $tree2->add_to_children({ content => '2 child 2' });
my $child2_3 = $tree2->add_to_children({ content => '2 child 3' });
my $child2_4 = $tree2->add_to_children({ content => '2 child 4' });

my $gchild2_1 = $child2_3->add_to_children({ content => '2 g-child 1' });
my $gchild2_2 = $child2_3->add_to_children({ content => '2 g-child 2' });
my $gchild2_3 = $child2_4->add_to_children({ content => '2 g-child 3' });
my $gchild2_4 = $child2_4->add_to_children({ content => '2 g-child 4' });

my $ggchild2 = $gchild2_3->add_to_children({ content => '2 gg-child 1' });

# Create a small test tree to graft
my $tree3 = $trees->create({ content => "3 tree root", root_id => 30});

# Try grafting it in as child of ggchild2
$ggchild2->_graft_branch({ node => $tree3, lft => 15, level => 4 });

$tree3->discard_changes;
is_deeply(
    [map { $_->id} $tree2->nodes],
    [map { $_->id} $tree2, $child2_1, $child2_2, $child2_3, $gchild2_1, $gchild2_2, $child2_4, $gchild2_3, $ggchild2, $tree3, $gchild2_4 ],
    'Tree is organised correctly after graft_branch tree3',
);

# graft rightmost child of root as left sibling of child 1
$child2_4->discard_changes;
$child2_2->discard_changes;
$child2_2->_graft_branch({ node => $child2_4, lft => 4, level => 1});

$tree2->discard_changes;
is_deeply(
    [map { $_->id} $tree2->nodes],
    [map { $_->id} $tree2, $child2_1, $child2_4, $gchild2_3, $ggchild2, $tree3, $gchild2_4, $child2_2, $child2_3, $gchild2_1, $gchild2_2, ],
    'Tree is organised correctly after _graft_branch',
);


# Now test the _attach_node which does both _move_to_end and _graft_branch
# Try to move it relative to itself
$child2_4->discard_changes;
throws_ok(sub {
    $child2_4->_attach_node($child2_4, {left_delta => 1, level => 2});
}, qr/Cannot _attach_node to it.s own descendant/, 'attaching node to itself');

$gchild2_4->discard_changes;
throws_ok(sub {
    $gchild2_4->_attach_node($child2_4, {left_delta => 1, level => 2});
}, qr/Cannot _attach_node to it.s own descendant/, 'attaching node to its own descendant');

# Attach a node back to its current place
$tree2->discard_changes;
$child2_1->discard_changes;
$tree2->_attach_node($child2_1, {left_delta => 1, level => 1});
$tree2->discard_changes;
is_deeply(
    [map { $_->id} $tree2->nodes],
    [map { $_->id} $tree2, $child2_1, $child2_4, $gchild2_3, $ggchild2, $tree3, $gchild2_4, $child2_2, $child2_3, $gchild2_1, $gchild2_2, ],
    'Tree is organised correctly after _attach_node back to current place',
);

# Attach a node at a lower level
$child2_3->discard_changes;
$gchild2_4->discard_changes;
$child2_3->_attach_node($gchild2_4, {left_delta => 1, level => $child2_3->level + 1});
is_deeply(
    [map { $_->id} $tree2->nodes],
    [map { $_->id} $tree2, $child2_1, $child2_4, $gchild2_3, $ggchild2, $tree3, $child2_2, $child2_3, $gchild2_4, $gchild2_1, $gchild2_2, ],
    'Tree is organised correctly after _attach_node at a lower level',
);

# Promote a gg-child to be a child
$child2_4->discard_changes;
$tree3->discard_changes;
$child2_4->_attach_node($tree3, {left_delta => 1, level => $child2_4->level + 1});
is_deeply(
    [map { $_->id} $tree2->nodes],
    [map { $_->id} $tree2, $child2_1, $child2_4, $tree3, $gchild2_3, $ggchild2, $child2_2, $child2_3, $gchild2_4, $gchild2_1, $gchild2_2, ],
    'Tree is organised correctly after _attach_node gg-child to be a child',
);

# Attach as the right-most child of root
$child2_3->discard_changes;
$tree2->discard_changes;
$tree2->_attach_node($child2_3, {left_delta => $tree2->rgt + 1 - $tree2->lft, level => $tree2->level + 1});

is_deeply(
    [map { $_->id} $tree2->nodes],
    [map { $_->id} $tree2, $child2_1, $child2_4, $tree3, $gchild2_3, $ggchild2, $child2_2, $child2_3, $gchild2_4, $gchild2_1, $gchild2_2, ],
    'Tree is organised correctly after _attach_node as right-most child of root',
);

done_testing();
exit;

