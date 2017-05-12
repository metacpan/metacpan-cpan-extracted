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
my $tree1 = $trees->create({ content => '1 tree root', root_id => 10});

my $child1_1 = $tree1->add_to_children({ content => '1 child 1' });
my $child1_2 = $tree1->add_to_children({ content => '1 child 2' });

# Check that the test tree is constructed correctly

is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_1, $child1_2],
    'Test Tree is organised correctly.',
);

$child1_1->discard_changes;
$tree1->discard_changes;

$child1_1->_move_to_end();

$tree1->attach_rightmost_child($child1_1);
my @children = $tree1->children;
is($children[1]->id, $child1_1->id, "Moved child to last child of root");



done_testing();
exit;

