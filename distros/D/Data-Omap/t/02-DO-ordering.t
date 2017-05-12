use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

my( $omap );

$omap = Data::Omap->new();
Data::Omap->order( 'sa' );  # string ascending

$omap->set( z => 26 );
$omap->set( y => 25 );
$omap->set( x => 24 );
is( Dumper($omap), "bless( [{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "set(), ordering 'sa'" );

$omap->add( a => 1 );
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "add(), ordering 'sa'" );

is( ref( Data::Omap->order() ), 'CODE',
    "order() returns code ref when ordering is on" );

is( Data::Omap->order( '' ), '',
    "order('') turns ordering off" );

$omap->add( b => 2 );
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}], 'Data::Omap' )",
    "add(), no ordering" );

$omap->clear();
Data::Omap->order( 'sa' );  # string ascending turned on again

$omap->set( 100 => 'hundred' );
$omap->set( 10  => 'ten' );
$omap->set( 2   => 'two' );
is( Dumper($omap), "bless( [{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "set(), ordering 'sa'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "add(), ordering 'sa'" );

$omap->clear();
Data::Omap->order( 'na' );  # number ascending

$omap->set( 100 => 'hundred' );
$omap->set( 10  => 'ten' );
$omap->set( 2   => 'two' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "set(), ordering 'na'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "add(), ordering 'na'" );

$omap->clear();
Data::Omap->order( 'sd' );  # string descending

$omap->set( x => 24 );
$omap->set( y => 25 );
$omap->set( z => 26 );
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24}], 'Data::Omap' )",
    "set(), ordering 'sd'" );

$omap->add( a => 1 );
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}], 'Data::Omap' )",
    "add(), ordering 'sd'" );

$omap->clear();

$omap->set( 2   => 'two' );  # order still 'sd'
$omap->set( 10  => 'ten' );
$omap->set( 100 => 'hundred' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}], 'Data::Omap' )",
    "set(), ordering 'sd'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}], 'Data::Omap' )",
    "add(), ordering 'sd'" );

$omap->clear();
Data::Omap->order( 'nd' );  # number descending

$omap->set( 2   => 'two' );
$omap->set( 10  => 'ten' );
$omap->set( 100 => 'hundred' );
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "set(), ordering 'nd'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}], 'Data::Omap' )",
    "add(), ordering 'nd'" );

$omap->clear();
Data::Omap->order( 'sna' );  # string/number ascending
$omap->set( z => 26 );
$omap->set( y => 25 );
$omap->add( x => 24 );  # set and add are the same for new key/value members
$omap->set( 100 => 'hundred' );
$omap->set( 10  => 'ten' );
$omap->add( 2   => 'two' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "set()/add(), ordering 'sna'" );

$omap->clear();
Data::Omap->order( 'snd' );  # string/number descending
$omap->add( x => 24 );  # set and add are the same for new key/value members
$omap->set( y => 25 );
$omap->set( z => 26 );
$omap->add( 2   => 'two' );
$omap->set( 10  => 'ten' );
$omap->set( 100 => 'hundred' );
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "set()/add(), ordering 'snd'" );

$omap->clear();
Data::Omap->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
$omap->set( 550 => "note" );
$omap->set( 500 => "note" );
$omap->set( 510 => "note" );
$omap->set( 650 => "subj" );
$omap->set( 600 => "subj" );
$omap->set( 610 => "subj" );
$omap->set( 245 => "title" );
$omap->set( 100 => "author" );
is( Dumper($omap), "bless( [{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}], 'Data::Omap' )",
    "set(), custom ordering" );

