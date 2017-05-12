# 04_alias.t
#
# Tests the tracking of object aliases

use Test::More tests => 46;

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

# pre-flight
ok( defined $obj1, 'instantiation 1' );
ok( defined $obj2, 'instantiation 2' );
ok( defined $obj3, 'instantiation 3' );
ok( defined $obj4, 'instantiation 4' );

# Pre-emptively apply aliases to 2 & 3
ok( $obj2->alias('o2'), 'alias 1' );
ok( $obj3->alias('o3'), 'alias 2' );

# Test realiasing
ok( !$obj3->alias('o33'), 'realias 1');

# Check pre-adoption aliases
is( $obj2->getByAlias('o2'), $obj2, 'pre-adoption alias 1');
is( $obj3->getByAlias('o3'), $obj3, 'pre-adoption alias 2');

# Build object hierarchy:
#   obj1 -> obj2 -> obj3, obj4
ok( $obj2->adopt( $obj3, $obj4 ), 'adopt 1' );
ok( $obj1->adopt($obj2), 'adopt 2' );

# Test realiasing
ok( !$obj3->alias('o33'), 'realias 2');

# Test inherited aliases via every object
is( $obj1->getByAlias('o2'), $obj2, 'get alias 1' );
is( $obj2->getByAlias('o2'), $obj2, 'get alias 2' );
is( $obj3->getByAlias('o2'), $obj2, 'get alias 3' );
is( $obj4->getByAlias('o2'), $obj2, 'get alias 4' );
is( $obj1->getByAlias('o3'), $obj3, 'get alias 5' );
is( $obj2->getByAlias('o3'), $obj3, 'get alias 6' );
is( $obj3->getByAlias('o3'), $obj3, 'get alias 7' );
is( $obj4->getByAlias('o3'), $obj3, 'get alias 8' );

# Test non-existent alias
is( $obj1->getByAlias('o1'), undef, 'get alias 9' );
is( $obj4->getByAlias(),     undef, 'get alias 10' );

# Alias o1 and o4
ok( $obj1->alias('o1'), 'alias 1' );
ok( $obj4->alias('o4'), 'alias 2' );

# Test new aliases via every object
is( $obj1->getByAlias('o1'), $obj1, 'get alias 11' );
is( $obj2->getByAlias('o1'), $obj1, 'get alias 12' );
is( $obj3->getByAlias('o1'), $obj1, 'get alias 13' );
is( $obj4->getByAlias('o1'), $obj1, 'get alias 14' );
is( $obj1->getByAlias('o4'), $obj4, 'get alias 15' );
is( $obj2->getByAlias('o4'), $obj4, 'get alias 16' );
is( $obj3->getByAlias('o4'), $obj4, 'get alias 17' );
is( $obj4->getByAlias('o4'), $obj4, 'get alias 18' );

# Disown o3 and test aliases again
ok( $obj2->disown($obj3), 'disown 1' );
is( $obj1->getByAlias('o3'), undef, 'get alias 19');
is( $obj4->getByAlias('o3'), undef, 'get alias 19');
is( $obj1->getByAlias('o2'), $obj2, 'get alias 20');
is( $obj4->getByAlias('o2'), $obj2, 'get alias 21');
is( $obj3->getByAlias('o1'), undef, 'get alias 22');
is( $obj3->getByAlias('o3'), $obj3, 'get alias 23');

# Disown o2 and test aliases
ok( $obj1->disown($obj2), 'disown 2');
is($obj1->getByAlias('o2'), undef, 'get alias 24');
is($obj1->getByAlias('o4'), undef, 'get alias 25');
is($obj1->getByAlias('o1'), $obj1, 'get alias 26');
is($obj2->getByAlias('o2'), $obj2, 'get alias 27');
is($obj2->getByAlias('o4'), $obj4, 'get alias 28');
is($obj4->getByAlias('o2'), $obj2, 'get alias 29');

