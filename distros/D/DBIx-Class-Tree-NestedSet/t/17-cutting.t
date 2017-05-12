#!/usr/bin/env perl
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
# taken from t/16-siblings.t
my $tree1 = $trees->create({ content => '1 tree root'});

my $child1_1 = $tree1->add_to_children({ content => '1 child 1' });
my $child1_2 = $tree1->add_to_children({ content => '1 child 2' });
my $child1_3 = $tree1->add_to_children({ content => '1 child 3' });
my $child1_4 = $tree1->add_to_children({ content => '1 child 4' });

my $gchild1_1 = $child1_2->add_to_children({ content => '1 g-child 1' });
my $gchild1_2 = $child1_2->add_to_children({ content => '1 g-child 2' });
my $gchild1_3 = $child1_4->add_to_children({ content => '1 g-child 3' });
my $gchild1_4 = $child1_4->add_to_children({ content => '1 g-child 4' });

my $ggchild1 = $gchild1_2->add_to_children({ content => '1 gg-child 1' });

sub refresh {
    for ($tree1, $child1_1,  $child1_2,  $child1_3,  $child1_4,
        $gchild1_1, $gchild1_2, $gchild1_3, $gchild1_4,
        $ggchild1) {

        $_->discard_changes;
    }
}

refresh();

# Check that the test tree is constructed correctly
is_deeply(
    [map { $_->id} $tree1->nodes],
    [map { $_->id} $tree1, $child1_1, $child1_2, $gchild1_1, $gchild1_2, $ggchild1, $child1_3, $child1_4, $gchild1_3, $gchild1_4],
    'Test Tree is organised correctly.',
);

my $subtree = $child1_2->take_cutting;
refresh();

is_deeply(
    [map { $_->id } $subtree->nodes],
    [map { $_->id } $child1_2, $gchild1_1, $gchild1_2, $ggchild1],
    'cut out tree is organised correctly.');

is_deeply(
    [map { $_->id } $tree1->nodes],
    [map { $_->id } $tree1, $child1_1, $child1_3, $child1_4, $gchild1_3, $gchild1_4],
    'remainder of tree intact.');

$subtree->dissolve;
refresh();
for ($subtree, $child1_2, $gchild1_1, $gchild1_2, $ggchild1) {
    ok $_->id == $_->root_id, 'dissolved node stands alone'

}

done_testing;
