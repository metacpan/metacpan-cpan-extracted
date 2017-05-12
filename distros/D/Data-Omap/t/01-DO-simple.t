use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Sortkeys=1;

BEGIN { use_ok('Data::Omap') };

my( $omap, @values, @keys, @array, $aref, $pos, %pos, $pos_href );

$omap = Data::Omap->new( [ {c=>3}, {a=>1}, {b=>2}, ] );

@values = $omap->get_values();
is( "@values", "3 1 2",
    "get_values(), all values, like 'values %hash'" );

@values = $omap->get_values( qw( a b c ) );
is( "@values", "3 1 2",
    "get_values(), selected values, like '\@hash{'c','a','b'}', i.e., data-ordered" );

@keys = $omap->get_keys();
is( "@keys", "c a b",
    "get_keys(), like 'keys %hash'" );

@keys = $omap->get_keys( qw( a b c ) );
is( "@keys", "c a b",
    "get_keys() for selected keys, data-ordered" );

$pos = $omap->get_pos( 'a' );
is( $pos, 1,
    "get_pos()" );

%pos = $omap->get_pos_hash();
is( Dumper(\%pos), "{'a' => 1,'b' => 2,'c' => 0}",
    "get_pos_hash(), all keys" );

%pos = $omap->get_pos_hash( 'a' );
is( Dumper(\%pos), "{'a' => 1}",
    "get_pos_hash(), one key" );

%pos = $omap->get_pos_hash( 'c', 'a' );
is( Dumper(\%pos), "{'a' => 1,'c' => 0}",
    "get_pos_hash(), multiple keys" );

@array = $omap->get_array();
is( Dumper(\@array), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "get_array(), list context" );

$aref = $omap->get_array();
is( Dumper($aref), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "get_array(), scalar context" );

@array = $omap->get_array( qw( b c ) );
is( Dumper(\@array), "[{'c' => 3},{'b' => 2}]",
    "get_array() for selected keys, data-ordered" );

$omap->set( a=>0 ); @values = $omap->get_values( qw( a b c ) );
is( "@values", "3 0 2",
    "set() a value" );

eval{ $omap->set( d=>4, 4 ); };
like( $@, qr/\$pos\(4\) too large/,
    "set(), pos too large" );

# at pos 1, overwrite 'a'
$omap->set( A=>1,1 ); @values = $omap->get_values( qw( A b c ) );
is( "@values", "3 1 2",
    "set() a value at a position" );

$omap->add( d=>4 ); @values = $omap->get_values( qw( A b c d ) );
is( "@values", "3 1 2 4",
    "add() a value" );

eval{ $omap->add( e=>5, 5 ); };
like( $@, qr/\$pos\(5\) too large/,
    "add(), pos too large" );

# add at pos 2, between 'A' and 'b'
$omap->add( a=>0,2 ); @values = $omap->get_values( qw( A a b c d ) );
is( "@values", "3 1 0 2 4",
    "add() a value at a position" );

# firstkey/nextkey to support TIEHASH
is( $omap->firstkey(), 'c',
    "firstkey()" );  
is( $omap->nextkey('c'), 'A',
    "nextkey()" );
is( $omap->nextkey('b'), 'd',
    "nextkey()" );

is( $omap->exists('a'), 1,
    "exists() true" );
is( $omap->exists('B'), '',
    "exists() false" );

$omap->delete('A');
is( Dumper($omap), "bless( [{'c' => 3},{'a' => 0},{'b' => 2},{'d' => 4}], 'Data::Omap' )",
    "delete()" );

$omap->clear();
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "clear()" );

