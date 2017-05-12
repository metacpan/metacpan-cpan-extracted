# 07_type_methods.t
#
# Tests the data type aware property methods

use Test::More tests => 42;

use strict;
use warnings;

package MyClass;

use vars qw(@ISA @_properties);
use Class::EHierarchy qw(:all);

@ISA = qw(Class::EHierarchy);

@_properties = (
    [ CEH_PUB | CEH_ARRAY, 'array', [qw(foo bar)] ],
    [ CEH_PUB | CEH_HASH, 'hash', {qw(foo bar)} ],
    );

1;

package main;

my $obj = new MyClass;
my ( $rv, @rv, %rv );

# Create our objects
ok( defined $obj, 'class object instantiation - 1' );

# Check initialized values
@rv = $obj->get('array');
%rv = $obj->get('hash');

is( scalar @rv,      2,     'array initialization - 1' );
is( $rv[0],          'foo', 'array initialization - 2' );
is( scalar keys %rv, 1,     'hash initialization - 1' );
is( $rv{foo},        'bar', 'hash initialization - 2' );

# Test array methods
is( $obj->push('array'),          2,   'push - 1' );
is( $obj->push(qw(array roo)),    3,   'push - 2' );
is( $obj->push(qw(array x y)),    5,   'push - 3' );
is( $obj->pop('array'),           'y', 'pop - 1' );
is( $obj->unshift('array'),       4,   'unshift - 1' );
is( $obj->unshift(qw(array i)),   5,   'unshift - 2' );
is( $obj->unshift(qw(array j k)), 7,   'unshift - 3' );
is( $obj->shift('array'),         'j', 'unshift - 4' );

# Test hash methods
ok( $obj->exists(qw(hash foo)),  'exists - 1' );
ok( !$obj->exists(qw(hash bar)), 'exists - 2' );
@rv = $obj->keys('hash');
is( scalar @rv, 1,     'keys - 1' );
is( $rv[0],     'foo', 'keys - 2' );

# Test unified methods
#
# Test merge
ok( $obj->merge(qw(array 1 a 3 b 5 c)), 'array merge - 1' );
@rv = $obj->get('array');
is( $rv[0], 'k', 'array merge - 2' );
is( $rv[1], 'a', 'array merge - 3' );
is( $rv[3], 'b', 'array merge - 4' );
is( $rv[5], 'c', 'array merge - 5' );
ok( $obj->merge(qw(hash x y j k)), 'hash merge - 1' );
%rv = $obj->get('hash');
is( $rv{foo}, 'bar', 'hash merge - 2' );
is( $rv{x},   'y',   'hash merge - 2' );
is( $rv{j},   'k',   'hash merge - 2' );

# Test subset
@rv = $obj->subset(qw(array 0 1 3 5));
is( scalar @rv, 4,   'array subset - 1' );
is( $rv[0],     'k', 'array subset - 2' );
is( $rv[3],     'c', 'array subset - 3' );
@rv = $obj->subset(qw(hash foo x));
is( scalar @rv, 2,     'hash subset - 1' );
is( $rv[0],     'bar', 'hash subset - 2' );
is( $rv[1],     'y',   'hash subset - 3' );

# Test remove
ok( $obj->remove(qw(array 1 3 5)), 'array remove - 1' );
@rv = $obj->get('array');
is( $rv[1], 'foo', 'array remove - 2' );
is( $rv[2], 'roo', 'array remove - 3' );
ok( $obj->remove(qw(hash foo x)), 'hash remove - 1' );
%rv = $obj->get('hash');
is( $rv{j}, 'k', 'hash remove - 2' );
ok( !exists $rv{x}, 'hash remove - 3' );

# Test empty
ok( $obj->empty('array'), 'array empty - 1' );
@rv = $obj->get('array');
is( scalar @rv, 0, 'array empty - 2' );
ok( $obj->empty('hash'), 'hash empty - 1' );
%rv = $obj->get('hash');
is( scalar keys %rv, 0, 'hash empty - 2' );
