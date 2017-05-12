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

# Add children to tree1
my $child1_1 = $tree1->add_to_children({ content => 'child1-1'});
my $child1_2 = $tree1->add_to_children({ content => 'child1-2'});
my $child1_3 = $tree1->add_to_children({ content => 'child1-3'});

# Add children to tree2
my $child2_1 = $tree2->add_to_children({ content => 'child2-1'});
my $child2_2 = $tree2->add_to_children({ content => 'child2-2'});

# Add grand-children to tree1
my $g_child1_1 = $child1_1->add_to_children({ content => 'g_child1-1'});
my $g_child1_2 = $child1_1->add_to_children({ content => 'g_child1-2'});
my $g_child1_3 = $child1_3->add_to_children({ content => 'g_child1-3'});

# Add grand-children to tree2
my $g_child2_1 = $child2_2->add_to_children({ content => 'g_child2-1'});
my $g_child2_2 = $child2_2->add_to_children({ content => 'g_child2-2'});

is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_1, $g_child1_1, $g_child1_2, $child1_2, $child1_3, $g_child1_3],
    'Tree 1 is organised correctly.',
);

is_deeply(
    [map { $_->id} $tree2->nodes],
    [map { $_->id} $tree2, $child2_1, $child2_2, $g_child2_1, $g_child2_2],
    'Tree 2 is organised correctly.',
);

my $tree3       = $trees->create({ content => 'tree1 root', root_id => 30});
my $child3_1    = $tree3->add_to_nodes({ content => 'child3-1'});
my $new_parent  = $child3_1->add_to_ancestors({ content => 'new parent'});

# The need for the following worries me. Creating a new node will cause the
# database to be updated (possibly every node) so what happens about instances
# such as $tree3 etc. which are modified in the database but not in memory?
$tree3->discard_changes;
$child3_1->discard_changes;
$new_parent->discard_changes;

is_deeply(
    [map {$_->id, $_->lft, $_->rgt, $_->level, $_->content} $tree3->nodes],
    [map {$_->id, $_->lft, $_->rgt, $_->level, $_->content} $tree3, $new_parent, $child3_1],
    'Tree 3 is organised correctly.',
    );

# See if we can re-root the tree
my $new_root    = $tree3->add_to_ancestors({ content => 'new root'});
$new_root->discard_changes;
$tree3->discard_changes;
$child3_1->discard_changes;
$new_parent->discard_changes;

is_deeply(
    [map {$_->id, $_->lft, $_->rgt, $_->level, $_->content} $new_root->nodes],
    [map {$_->id, $_->lft, $_->rgt, $_->level, $_->content} $new_root, $tree3, $new_parent, $child3_1],
    'Tree 3 is organised correctly.',
    );

done_testing();
exit;

