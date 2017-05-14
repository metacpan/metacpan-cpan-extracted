#! /usr/bin/perl -w
# Test adapted from DBIx-Class-EncodedColumn-0.00006

use strict;
use warnings;
use Test::More;

use File::Spec;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');

my $tests = 86;

plan tests => $tests;

#1
use_ok("CdbiTreeTest");

my $schema = CdbiTreeTest->init_schema;
my $rs     = $schema->resultset('Test');

# bug in SQLite
# http://www.sqlite.org/src/tktview?name=1248e6cda8
Math::BigFloat->accuracy(15); 

sub ids_list {
    my $rs = shift;
    return '' unless ref($rs);
    return ($rs->id) unless $rs->can('next');
    my @ids = ();
    while (my $rec = $rs->next) { push(@ids, $rec->id) }
    return join(',', @ids);
}

is(join('/', DBIx::Class::Tree::Mobius::_rational()), '', 'reverse order Euclidean algorithm for (empty list)');
is(join('/', DBIx::Class::Tree::Mobius::_rational(3)), '3/1', 'reverse Euclidean algorithm for (3)');
is(join('/', DBIx::Class::Tree::Mobius::_rational(3,12,5,1,21)), '4913/1594', 'reverse Euclidean algorithm for (3,12,5,1,21)');
is(join('.', DBIx::Class::Tree::Mobius::_euclidean(4913,1594)), '3.12.5.1.21', 'Euclidean algorithm for (4913/1594)');

is(DBIx::Class::Tree::Mobius::_mobius_encoding(3,12,5,1,21), '(4913x + 225) / (1594x + 73)', 'mobius encoding for (3,12,5,1,21)');
is(DBIx::Class::Tree::Mobius::_mobius_encoding(3,12,5,1), '(225x + 188) / (73x + 61)', 'mobius encoding for (3,12,5,1)');
is(DBIx::Class::Tree::Mobius::_mobius_encoding(3,12,5), '(188x + 37) / (61x + 12)', 'mobius encoding for (3,12,5)');
is(DBIx::Class::Tree::Mobius::_mobius_encoding(3,12), '(37x + 3) / (12x + 1)', 'mobius encoding for (3,12)');
is(DBIx::Class::Tree::Mobius::_mobius_encoding(3), '(3x + 1) / (1x + 0)', 'mobius encoding for (3)');

# global root is implicit
is(DBIx::Class::Tree::Mobius::_mobius_encoding(), '(1x + 0) / (0x + 1)', 'mobius encoding for ()');

# ! rational representation is ambiguous for 1 ...
is(join('/', DBIx::Class::Tree::Mobius::_rational(4)), '4/1', 'reverse Euclidean algorithm for (4)');
is(join('/', DBIx::Class::Tree::Mobius::_rational(3,1)), '4/1', 'reverse Euclidean algorithm for (3,1)');
is(join('.', DBIx::Class::Tree::Mobius::_euclidean(4,1)), '4', 'Euclidean algorithm for (4/1)');

# so our internal materialized path use integer > 1
is(DBIx::Class::Tree::Mobius::_mobius_encoding(5), '(5x + 1) / (1x + 0)', 'mobius encoding for (5)');
is(DBIx::Class::Tree::Mobius::_mobius_encoding(4,2), '(9x + 4) / (2x + 1)', 'mobius encoding for (4,2)');

is(DBIx::Class::Tree::Mobius::_mobius_path(5,1,1,0), '5', 'reverse materialized path for (5x + 1) / (1x + 0)');
is(DBIx::Class::Tree::Mobius::_mobius_path(9,4,2,1), '4.2', 'reverse materialized path for (9x + 4) / (2x + 1)');

#is(DBIx::Class::Tree::Mobius::_left_right(37, 12), 'l=3.077, r=3.083', 'interval for rational 37/12');

my $id1 = $rs->create({ data => 'first rec' });
my $id2 = $rs->create({ data => 'second rec' });
my $id3 = $rs->create({ data => 'third rec' });

is($id3->mobius_path, '2', 'check mobius path rec id 3');

my $id4 = $rs->create({ data => 'rec 3 child 1' });
my $id5 = $rs->create({ data => 'rec 3 child 2' });

$id3->attach_child( $id4 );
is($id3->mobius_path, '3', 'check mobius path rec id 3');
#is($id3->child_encoding(2), '(9x + 4) / (2x + 1)', 'check enconding rec id 3');

$id3->attach_child( $id5 );
is($id3->mobius_path, '3', 'check mobius path rec id 3');

my $id6 = $rs->create({ parent => $id3->id, data => 'rec 3 child 3' });
is($id3->mobius_path, '3', 'check mobius path rec id 3');

is($id4->mobius_path, '3.2', 'check mobius path rec 3 child 1');
is($id5->mobius_path, '3.2', 'check mobius path rec 3 child 2');
is($id6->mobius_path, '3.2', 'check mobius path rec 3 child 3');

is($id3->descendants()->count, '3', 'check descendants count rec id 3');

#is(DBIx::Class::Tree::Mobius::_left_right($id4->tree_num, $id4->tree_den), 'l=3.200, r=3.250', 'left right values rec 3_1');
#is(DBIx::Class::Tree::Mobius::_left_right($id5->tree_num, $id5->tree_den), 'l=3.167, r=3.200', 'left right values rec 3_2');
#is(DBIx::Class::Tree::Mobius::_left_right($id6->tree_num, $id6->tree_den), 'l=3.143, r=3.167', 'left right values rec 3_3');

my $id7 = $rs->create({ data => 'rec 3_2 child 1' });
$id5->attach_child( $id7 );
my $id8 = $rs->create({ parent => $id5->id, data => 'rec 3_2 child 2' });

my $id9 = $rs->create({ parent => $id1->id, data => 'rec 1 child 1' });
my $id10 = $rs->create({ parent => $id9->id, data => 'rec 1_1 child 1' });

my $id11 = $rs->create({ data => 'fourth rec' });

my $id12 = $rs->create({ parent => $id7->id, data => 'rec 3_2_1_1 child 1' });

$id1 = $id1->get_from_storage();

# This test case has built 4 trees
# Root nodes are id 1, 2, 3 and 11 
#
#  1       2       3        11   
#  |              / \
#  9             4   5
#  |                / \
#  10              7   8
#                 /
#               12

is($id1->parent, undef, 'check id1 parent');
#is(ids_list(scalar $id1->siblings), '2,3,11', 'check id1 siblings');
is(ids_list(scalar $id1->children), '9', 'check id1 children');
is(ids_list(scalar $id1->inner_children), '9', 'check id1 inner children');
is(ids_list(scalar $id1->leaf_children), '', 'check id1 leaf children');
is(ids_list(scalar $id1->descendants), '9,10', 'check id1 descendants');
is(ids_list(scalar $id1->inner_descendants), '9', 'check id1 inner descendants');
is(ids_list(scalar $id1->leaves), '10', 'check id1 leaves');
is(ids_list(scalar $id1->root), '1', 'check id1 root');
is(ids_list(scalar $id1->ascendants), '', 'check id1 ascendants');
is($id1->depth, '1', 'check id1 depth');

$id3 = $id3->get_from_storage();
is($id3->parent, undef, 'check id3 parent');
#is(ids_list(scalar $id3->siblings), '1,2,11', 'check id3 siblings');
is(ids_list(scalar $id3->children), '4,5,6', 'check id3 children');
is(ids_list(scalar $id3->inner_children), '5', 'check id3 inner children');
is(ids_list(scalar $id3->leaf_children), '4,6', 'check id3 leaf children');
is(ids_list(scalar $id3->descendants), '4,5,6,7,8,12', 'check id3 descendants');
is(ids_list(scalar $id3->inner_descendants), '5,7', 'check id3 inner descendants');
is(ids_list(scalar $id3->leaves), '4,6,8,12', 'check id3 leaves');
is(ids_list(scalar $id3->root), '3', 'check id3 root');
is(ids_list(scalar $id3->ascendants), '', 'check id3 ascendants');
is($id3->depth, '1', 'check id3 depth');

$id4 = $id4->get_from_storage();
is($id4->parent->id, 3, 'check id4 parent');
#is(ids_list(scalar $id4->siblings), '5,6', 'check id4 siblings');
is(ids_list(scalar $id4->children), '', 'check id4 children');
is(ids_list(scalar $id4->inner_children), '', 'check id4 inner children');
is(ids_list(scalar $id4->leaf_children), '', 'check id4 leaf children');
is(ids_list(scalar $id4->descendants), '', 'check id4 descendants');
is(ids_list(scalar $id4->inner_descendants), '', 'check id4 inner descendants');
is(ids_list(scalar $id4->leaves), '', 'check id4 leaves');
is(ids_list(scalar $id4->root), '3', 'check id4 root');
is(ids_list(scalar $id4->ascendants), '3', 'check id4 ascendants');
is($id4->depth, '2', 'check id4 depth');

$id7 = $id7->get_from_storage();
is($id7->parent->id, 5, 'check id7 parent');
#is(ids_list(scalar $id7->siblings), '8', 'check id7 siblings');
is(ids_list(scalar $id7->children), '12', 'check id7 children');
is(ids_list(scalar $id7->inner_children), '', 'check id7 inner children');
is(ids_list(scalar $id7->leaf_children), '12', 'check id7 leaf children');
is(ids_list(scalar $id7->descendants), '12', 'check id7 descendants');
is(ids_list(scalar $id7->inner_descendants), '', 'check id7 inner descendants');
is(ids_list(scalar $id7->leaves), '12', 'check id7 leaves');
is(ids_list(scalar $id7->root), '3', 'check id7 root');
is(ids_list(scalar $id7->ascendants), '5,3', 'check id7 ascendants');
is($id7->depth, '3', 'check id7 depth');

$id11 = $id11->get_from_storage();
is($id11->parent, undef, 'check id11 parent');
#is(ids_list(scalar $id11->siblings), '1,2,3', 'check id11 siblings');
is(ids_list(scalar $id11->children), '', 'check id11 children');
is(ids_list(scalar $id11->inner_children), '', 'check id11 inner children');
is(ids_list(scalar $id11->leaf_children), '', 'check id11 leaf children');
is(ids_list(scalar $id11->descendants), '', 'check id11 descendants');
is(ids_list(scalar $id11->inner_descendants), '', 'check id11 inner descendants');
is(ids_list(scalar $id11->leaves), '', 'check id11 leaves');
is(ids_list(scalar $id11->root), '11', 'check id11 root');
is(ids_list(scalar $id11->ascendants), '', 'check id11 ascendants');
is($id11->depth, '1', 'check id11 depth');

$id12 = $id12->get_from_storage();
is($id12->parent->id, 7, 'check id12 parent');
#is(ids_list(scalar $id12->siblings), '', 'check id12 siblings');
is(ids_list(scalar $id12->children), '', 'check id12 children');
is(ids_list(scalar $id12->inner_children), '', 'check id12 inner children');
is(ids_list(scalar $id12->leaf_children), '', 'check id12 leaf children');
is(ids_list(scalar $id12->descendants), '', 'check id12 descendants');
is(ids_list(scalar $id12->inner_descendants), '', 'check id12 inner descendants');
is(ids_list(scalar $id12->leaves), '', 'check id12 leaves');
is(ids_list(scalar $id12->root), '3', 'check id12 root');
is(ids_list(scalar $id12->ascendants), '7,5,3', 'check id12 ascendants');
is($id12->depth, '4', 'check id12 depth');



END {
    # In the END section so that the test DB file gets closed before we attempt to unlink it
    CdbiTreeTest::clear($schema);
}

1;
