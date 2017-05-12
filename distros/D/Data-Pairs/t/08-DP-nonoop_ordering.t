use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Pairs', ':ALL') };

my( $pairs );

$pairs = [];
pairs_order( $pairs, 'sa' );  # string ascending

pairs_set( $pairs, z => 26 );
pairs_set( $pairs, y => 25 );
pairs_set( $pairs, x => 24 );
is( Dumper($pairs), "[{'x' => 24},{'y' => 25},{'z' => 26}]",
    "pairs_set(), ordering 'sa'" );

pairs_add( $pairs, a => 1 );
is( Dumper($pairs), "[{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}]",
    "pairs_add(), ordering 'sa'" );

is( ref( Data::Pairs->order() ), 'CODE',
    "pairs_order() returns code ref when ordering is on" );

is( Data::Pairs->order( '' ), '',
    "pairs_order('') turns ordering off" );

pairs_add( $pairs, b => 2 );
is( Dumper($pairs), "[{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}]",
    "pairs_add(), no ordering" );

pairs_clear( $pairs );
Data::Pairs->order( 'sa' );  # string ascending turned on again

pairs_set( $pairs, 100 => 'hundred' );
pairs_set( $pairs, 10  => 'ten' );
pairs_set( $pairs, 2   => 'two' );
is( Dumper($pairs), "[{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}]",
    "pairs_set(), ordering 'sa'" );

pairs_add( $pairs, 1 => 'one' );
is( Dumper($pairs), "[{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}]",
    "pairs_add(), ordering 'sa'" );

pairs_clear( $pairs );
Data::Pairs->order( 'na' );  # number ascending

pairs_set( $pairs, 100 => 'hundred' );
pairs_set( $pairs, 10  => 'ten' );
pairs_set( $pairs, 2   => 'two' );
is( Dumper($pairs), "[{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}]",
    "pairs_set(), ordering 'na'" );

pairs_add( $pairs, 1 => 'one' );
is( Dumper($pairs), "[{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}]",
    "pairs_add(), ordering 'na'" );

pairs_clear( $pairs );
Data::Pairs->order( 'sd' );  # string descending

pairs_set( $pairs, x => 24 );
pairs_set( $pairs, y => 25 );
pairs_set( $pairs, z => 26 );
is( Dumper($pairs), "[{'z' => 26},{'y' => 25},{'x' => 24}]",
    "pairs_set(), ordering 'sd'" );

pairs_add( $pairs, a => 1 );
is( Dumper($pairs), "[{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}]",
    "pairs_add(), ordering 'sd'" );

pairs_clear( $pairs );

pairs_set( $pairs, 2   => 'two' );  # order still 'sd'
pairs_set( $pairs, 10  => 'ten' );
pairs_set( $pairs, 100 => 'hundred' );
is( Dumper($pairs), "[{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}]",
    "pairs_set(), ordering 'sd'" );

pairs_add( $pairs, 1 => 'one' );
is( Dumper($pairs), "[{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}]",
    "pairs_add(), ordering 'sd'" );

pairs_clear( $pairs );
Data::Pairs->order( 'nd' );  # number descending

pairs_set( $pairs, 2   => 'two' );
pairs_set( $pairs, 10  => 'ten' );
pairs_set( $pairs, 100 => 'hundred' );
is( Dumper($pairs), "[{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}]",
    "pairs_set(), ordering 'nd'" );

pairs_add( $pairs, 1 => 'one' );
is( Dumper($pairs), "[{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}]",
    "pairs_add(), ordering 'nd'" );

pairs_clear( $pairs );
Data::Pairs->order( 'sna' );  # string/number ascending
pairs_set( $pairs, z => 26 );
pairs_set( $pairs, y => 25 );
pairs_add( $pairs, x => 24 );  # set and add are the same for new key/value members
pairs_set( $pairs, 100 => 'hundred' );
pairs_set( $pairs, 10  => 'ten' );
pairs_add( $pairs, 2   => 'two' );
is( Dumper($pairs), "[{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}]",
    "pairs_set()/add(), ordering 'sna'" );

pairs_clear( $pairs );
Data::Pairs->order( 'snd' );  # string/number descending
pairs_add( $pairs, x => 24 );  # set and add are the same for new key/value members
pairs_set( $pairs, y => 25 );
pairs_set( $pairs, z => 26 );
pairs_add( $pairs, 2   => 'two' );
pairs_set( $pairs, 10  => 'ten' );
pairs_set( $pairs, 100 => 'hundred' );
is( Dumper($pairs), "[{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}]",
    "pairs_set()/add(), ordering 'snd'" );

pairs_clear( $pairs );
Data::Pairs->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
pairs_set( $pairs, 550 => "note" );
pairs_set( $pairs, 500 => "note" );
pairs_set( $pairs, 510 => "note" );
pairs_set( $pairs, 650 => "subj" );
pairs_set( $pairs, 600 => "subj" );
pairs_set( $pairs, 610 => "subj" );
pairs_set( $pairs, 245 => "title" );
pairs_set( $pairs, 100 => "author" );
is( Dumper($pairs), "[{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}]",
    "pairs_set(), custom ordering" );

