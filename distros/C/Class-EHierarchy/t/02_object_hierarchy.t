# 02_object_hierarchy.t
#
# Tests the tracking of object relationships

use Test::More tests => 27;

use strict;
use warnings;

use Class::EHierarchy;

sub dumpObjInfo {
    my $obj = shift;
    my ( $id, $parent, $children );

    $id       = $$obj;
    $parent   = defined $obj->parent ? ${ $obj->parent } : 'undef';
    $children = join ' ', map {$$_} $obj->children;

    warn "ID $id: P: $parent C: $children\n";
}

my $obj1 = new Class::EHierarchy;
my $obj2 = new Class::EHierarchy;
my $obj3 = new Class::EHierarchy;
my $obj4 = new Class::EHierarchy;

# Test isStale
$obj1->DESTROY;
ok( $obj1->isStale,      'isStale 1' );
ok( !$obj1->root,        'isStale 2' );
ok( !$obj1->parent,      'isStale 3' );
ok( !$obj1->children,    'isStale 4' );
ok( !$obj1->siblings,    'isStale 5' );
ok( !$obj1->descendents, 'isStale 6' );

$obj1 = new Class::EHierarchy;
is( $$obj1, 0, 'recover ID 1' );

# Test basic adoption
ok( !$obj1->adopt($obj1), 'Adopt Self 1' );
ok( $obj1->adopt($obj2),  'Adopt Child 1' );
is( $obj2->children, 0, 'Children 1' );
is( $obj1->children, 1, 'Children 2' );
ok( !$obj2->adopt($obj1), 'Adopt Parent 1' );
ok( $obj2->adopt($obj3),  'Adopt Child 2' );
is( $obj1->children,    1, 'Children 3' );
is( $obj2->children,    1, 'Children 4' );
is( $obj1->descendents, 2, 'descendents 1' );
ok( !$obj3->adopt($obj1), 'Adopt Root 1' );

# Test parent
is( $obj1->parent, undef, 'Parent 1' );
is( $obj3->parent, $obj2, 'Parent 2' );

# Test root
is( $obj1->root, $obj1, 'Root 1' );
is( $obj3->root, $obj1, 'Root 2' );

# Test descendents
my @children = $obj1->descendents;
is( $children[0], $obj2, 'descendent 1' );
is( $children[1], $obj3, 'descendent 2' );

# Adopt the root with obj4
ok( $obj4->adopt($obj1), 'Adopt Child 3' );

# Test disowning
ok( $obj1->disown($obj2), 'Disown 1' );
is( $obj1->children, 0,     'Children 6' );
is( $obj2->parent,   undef, 'Parent 3' );

