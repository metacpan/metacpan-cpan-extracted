use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Sortkeys=1;

BEGIN { use_ok('Data::Pairs', ':ALL') };

my( $pairs, @values, @keys, @array, $aref, %pos, $pos );

$pairs = [ {c=>3}, {a=>1}, {b=>2}, ];

@values = pairs_get_values( $pairs );
is( "@values", "3 1 2",
    "pairs_get_values(), all values, like 'values %hash'" );

@values = pairs_get_values( $pairs, qw( a b c ) );
is( "@values", "3 1 2",
    "pairs_get_values(), selected values, like '\@hash{'c','a','b'}', i.e., data-ordered" );

@keys = pairs_get_keys( $pairs );
is( "@keys", "c a b",
    "pairs_get_keys(), like 'keys %hash'" );

@keys = pairs_get_keys( $pairs, qw( a b c ) );
is( "@keys", "c a b",
    "pairs_get_keys() for selected keys, data-ordered" );

@array = pairs_get_array( $pairs );
is( Dumper(\@array), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "pairs_get_array(), list context" );

$aref = pairs_get_array( $pairs );
is( Dumper($aref), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "pairs_get_array(), scalar context" );

@array = pairs_get_array( $pairs, qw( b c ) );
is( Dumper(\@array), "[{'c' => 3},{'b' => 2}]",
    "pairs_get_array() for selected keys, data-ordered" );

pairs_set( $pairs, a=>0 ); @values = pairs_get_values( $pairs, qw( a b c ) );
is( "@values", "3 0 2",
    "pairs_set() a value" );

eval{ pairs_set( $pairs, d=>4, 4 ); };
like( $@, qr/\$pos\(4\) too large/,
    "pairs_set(), pos too large" );

# at pos 1, overwrite 'a'
pairs_set( $pairs, A=>1,1 ); @values = pairs_get_values( $pairs, qw( A b c ) );
is( "@values", "3 1 2",
    "pairs_set() a value at a position" );

pairs_add( $pairs, d=>4 ); @values = pairs_get_values( $pairs, qw( A b c d ) );
is( "@values", "3 1 2 4",
    "pairs_add() a value" );

eval{ pairs_add( $pairs, e=>5, 5 ); };
like( $@, qr/\$pos\(5\) too large/,
    "pairs_add(), pos too large" );

# add at pos 2, between 'A' and 'b'
pairs_add( $pairs, a=>0,2 ); @values = pairs_get_values( $pairs, qw( A a b c d ) );
is( "@values", "3 1 0 2 4",
    "pairs_add() a value at a position" );

is( pairs_exists( $pairs, 'a' ), 1,
    "pairs_exists() true" );
is( pairs_exists( $pairs, 'B' ), '',
    "pairs_exists() false" );

pairs_delete( $pairs, 'A' );
is( Dumper($pairs), "[{'c' => 3},{'a' => 0},{'b' => 2},{'d' => 4}]",
    "pairs_delete(), single key" );

pairs_clear( $pairs );
is( Dumper($pairs), "[]",
    "pairs_clear()" );

$pairs = [ {c=>3}, {a=>1}, {b=>2}, {a=>4} ];

$pos = pairs_get_pos( $pairs, 'c' );
is( $pos, 0,
    "pairs_get_pos(), key appears once" );

$pos = pairs_get_pos( $pairs, 'a' );
is( Dumper($pos), "[1,3]",
    "pairs_get_pos(), key appears more than once" );

%pos = pairs_get_pos_hash( $pairs );
is( Dumper(\%pos), "{'a' => [1,3],'b' => [2],'c' => [0]}",
    "pairs_get_pos_hash(), list, all" );

$pos = pairs_get_pos_hash( $pairs );
is( Dumper($pos), "{'a' => [1,3],'b' => [2],'c' => [0]}",
    "pairs_get_pos_hash(), scalar, all" );

%pos = pairs_get_pos_hash( $pairs, 'c', 'a' );
is( Dumper(\%pos), "{'a' => [1,3],'c' => [0]}",
    "pairs_get_pos_hash(), list, selected keys" );

$pos = pairs_get_pos_hash( $pairs, 'c', 'a' );
is( Dumper($pos), "{'a' => [1,3],'c' => [0]}",
    "pairs_get_pos_hash(), scalar, selected keys" );

pairs_delete( $pairs, a => 3 );
is( Dumper($pairs), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "pairs_delete(), at position" );

