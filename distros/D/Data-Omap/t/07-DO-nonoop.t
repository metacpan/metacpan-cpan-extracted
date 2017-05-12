use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Sortkeys=1;

BEGIN { use_ok('Data::Omap', ':ALL') };

my( $omap, @values, @keys, @array, $aref, $pos, %pos, $pos_href );

$omap = [ {c=>3}, {a=>1}, {b=>2}, ];

@values = omap_get_values( $omap );
is( "@values", "3 1 2",
    "get_values(), all values, like 'values %hash'" );

@values = omap_get_values( $omap, qw( a b c ) );
is( "@values", "3 1 2",
    "get_values(), selected values, like '\@hash{'c','a','b'}', i.e., data-ordered" );

@keys = omap_get_keys( $omap );
is( "@keys", "c a b",
    "get_keys(), like 'keys %hash'" );

@keys = omap_get_keys( $omap, qw( a b c ) );
is( "@keys", "c a b",
    "get_keys() for selected keys, data-ordered" );

$pos = omap_get_pos( $omap, 'a' );
is( $pos, 1,
    "get_pos()" );

%pos = omap_get_pos_hash( $omap );
is( Dumper(\%pos), "{'a' => 1,'b' => 2,'c' => 0}",
    "get_pos_hash(), all keys" );

%pos = omap_get_pos_hash( $omap, 'a' );
is( Dumper(\%pos), "{'a' => 1}",
    "get_pos_hash(), one key" );

%pos = omap_get_pos_hash( $omap, 'c', 'a' );
is( Dumper(\%pos), "{'a' => 1,'c' => 0}",
    "get_pos_hash(), multiple keys" );

@array = omap_get_array( $omap );
is( Dumper(\@array), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "get_array(), list context" );

$aref = omap_get_array( $omap );
is( Dumper($aref), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "get_array(), scalar context" );

@array = omap_get_array( $omap, qw( b c ) );
is( Dumper(\@array), "[{'c' => 3},{'b' => 2}]",
    "get_array() for selected keys, data-ordered" );

omap_set( $omap, a=>0 ); @values = omap_get_values( $omap, qw( a b c ) );
is( "@values", "3 0 2",
    "set() a value" );

eval{ omap_set( $omap, d=>4, 4 ); };
like( $@, qr/\$pos\(4\) too large/,
    "set(), pos too large" );

# at pos 1, overwrite 'a'
omap_set( $omap, A=>1,1 ); @values = omap_get_values( $omap, qw( A b c ) );
is( "@values", "3 1 2",
    "set() a value at a position" );

omap_add( $omap, d=>4 ); @values = omap_get_values( $omap, qw( A b c d ) );
is( "@values", "3 1 2 4",
    "add() a value" );

eval{ omap_add( $omap, e=>5, 5 ); };
like( $@, qr/\$pos\(5\) too large/,
    "add(), pos too large" );

# add at pos 2, between 'A' and 'b'
omap_add( $omap, a=>0,2 ); @values = omap_get_values( $omap, qw( A a b c d ) );
is( "@values", "3 1 0 2 4",
    "add() a value at a position" );

is( omap_exists( $omap, 'a'), 1,
    "exists() true" );
is( omap_exists( $omap, 'B'), '',
    "exists() false" );

omap_delete( $omap, 'A');
is( Dumper($omap), "[{'c' => 3},{'a' => 0},{'b' => 2},{'d' => 4}]",
    "delete()" );

omap_clear( $omap );
is( Dumper($omap), "[]",
    "clear()" );

