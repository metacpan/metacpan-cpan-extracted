use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

use Data::Omap ':ALL';

my( $omap );

$omap = [];
omap_order( $omap, 'sa' );  # string ascending

omap_set( $omap, z => 26 );
omap_set( $omap, y => 25 );
omap_set( $omap, x => 24 );
is( Dumper($omap), "[{'x' => 24},{'y' => 25},{'z' => 26}]",
    "omap_set(), ordering 'sa'" );

omap_add( $omap, a => 1 );
is( Dumper($omap), "[{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}]",
    "omap_add(), ordering 'sa'" );

is( ref( omap_order() ), 'CODE',
    "omap_order() returns code ref when ordering is on" );

is( omap_order( $omap, '' ), '',
    "omap_order('') turns ordering off" );

omap_add( $omap, b => 2 );
is( Dumper($omap), "[{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}]",
    "omap_add(), no ordering" );

omap_clear( $omap );
omap_order( $omap, 'sa' );  # string ascending turned on again

omap_set( $omap, 100 => 'hundred' );
omap_set( $omap, 10  => 'ten' );
omap_set( $omap, 2   => 'two' );
is( Dumper($omap), "[{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}]",
    "omap_set(), ordering 'sa'" );

omap_add( $omap, 1 => 'one' );
is( Dumper($omap), "[{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}]",
    "omap_add(), ordering 'sa'" );

omap_clear( $omap );
omap_order( $omap, 'na' );  # number ascending

omap_set( $omap, 100 => 'hundred' );
omap_set( $omap, 10  => 'ten' );
omap_set( $omap, 2   => 'two' );
is( Dumper($omap), "[{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}]",
    "omap_set(), ordering 'na'" );

omap_add( $omap, 1 => 'one' );
is( Dumper($omap), "[{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}]",
    "omap_add(), ordering 'na'" );

omap_clear( $omap );
omap_order( $omap, 'sd' );  # string descending

omap_set( $omap, x => 24 );
omap_set( $omap, y => 25 );
omap_set( $omap, z => 26 );
is( Dumper($omap), "[{'z' => 26},{'y' => 25},{'x' => 24}]",
    "omap_set(), ordering 'sd'" );

omap_add( $omap, a => 1 );
is( Dumper($omap), "[{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}]",
    "omap_add(), ordering 'sd'" );

omap_clear( $omap );

omap_set( $omap, 2   => 'two' );  # order still 'sd'
omap_set( $omap, 10  => 'ten' );
omap_set( $omap, 100 => 'hundred' );
is( Dumper($omap), "[{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}]",
    "omap_set(), ordering 'sd'" );

omap_add( $omap, 1 => 'one' );
is( Dumper($omap), "[{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}]",
    "omap_add(), ordering 'sd'" );

omap_clear( $omap );
omap_order( $omap, 'nd' );  # number descending

omap_set( $omap, 2   => 'two' );
omap_set( $omap, 10  => 'ten' );
omap_set( $omap, 100 => 'hundred' );
is( Dumper($omap), "[{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}]",
    "omap_set(), ordering 'nd'" );

omap_add( $omap, 1 => 'one' );
is( Dumper($omap), "[{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}]",
    "omap_add(), ordering 'nd'" );

omap_clear( $omap );
omap_order( $omap, 'sna' );  # string/number ascending
omap_set( $omap, z => 26 );
omap_set( $omap, y => 25 );
omap_add( $omap, x => 24 );  # set and add are the same for new key/value members
omap_set( $omap, 100 => 'hundred' );
omap_set( $omap, 10  => 'ten' );
omap_add( $omap, 2   => 'two' );
is( Dumper($omap), "[{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}]",
    "omap_set()/omap_add(), ordering 'sna'" );

omap_clear( $omap );
omap_order( $omap, 'snd' );  # string/number descending
omap_add( $omap, x => 24 );  # set and add are the same for new key/value members
omap_set( $omap, y => 25 );
omap_set( $omap, z => 26 );
omap_add( $omap, 2   => 'two' );
omap_set( $omap, 10  => 'ten' );
omap_set( $omap, 100 => 'hundred' );
is( Dumper($omap), "[{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}]",
    "omap_set()/omap_add(), ordering 'snd'" );

omap_clear( $omap );
omap_order( $omap, sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
omap_set( $omap, 550 => "note" );
omap_set( $omap, 500 => "note" );
omap_set( $omap, 510 => "note" );
omap_set( $omap, 650 => "subj" );
omap_set( $omap, 600 => "subj" );
omap_set( $omap, 610 => "subj" );
omap_set( $omap, 245 => "title" );
omap_set( $omap, 100 => "author" );
is( Dumper($omap), "[{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}]",
    "omap_set(), custom ordering" );

