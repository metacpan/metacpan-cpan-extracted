use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Pairs') };

my( $pairs );

$pairs = Data::Pairs->new();
Data::Pairs->order( 'sa' );  # string ascending

$pairs->set( z => 26 );
$pairs->set( y => 25 );
$pairs->set( x => 24 );
is( Dumper($pairs), "bless( [{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Pairs' )",
    "set(), ordering 'sa'" );

$pairs->add( a => 1 );
is( Dumper($pairs), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Pairs' )",
    "add(), ordering 'sa'" );

is( ref( Data::Pairs->order() ), 'CODE',
    "order() returns code ref when ordering is on" );

is( Data::Pairs->order( '' ), '',
    "order('') turns ordering off" );

$pairs->add( b => 2 );
is( Dumper($pairs), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}], 'Data::Pairs' )",
    "add(), no ordering" );

$pairs->clear();
Data::Pairs->order( 'sa' );  # string ascending turned on again

$pairs->set( 100 => 'hundred' );
$pairs->set( 10  => 'ten' );
$pairs->set( 2   => 'two' );
is( Dumper($pairs), "bless( [{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Pairs' )",
    "set(), ordering 'sa'" );

$pairs->add( 1 => 'one' );
is( Dumper($pairs), "bless( [{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Pairs' )",
    "add(), ordering 'sa'" );

$pairs->clear();
Data::Pairs->order( 'na' );  # number ascending

$pairs->set( 100 => 'hundred' );
$pairs->set( 10  => 'ten' );
$pairs->set( 2   => 'two' );
is( Dumper($pairs), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Pairs' )",
    "set(), ordering 'na'" );

$pairs->add( 1 => 'one' );
is( Dumper($pairs), "bless( [{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Pairs' )",
    "add(), ordering 'na'" );

$pairs->clear();
Data::Pairs->order( 'sd' );  # string descending

$pairs->set( x => 24 );
$pairs->set( y => 25 );
$pairs->set( z => 26 );
is( Dumper($pairs), "bless( [{'z' => 26},{'y' => 25},{'x' => 24}], 'Data::Pairs' )",
    "set(), ordering 'sd'" );

$pairs->add( a => 1 );
is( Dumper($pairs), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}], 'Data::Pairs' )",
    "add(), ordering 'sd'" );

$pairs->clear();

$pairs->set( 2   => 'two' );  # order still 'sd'
$pairs->set( 10  => 'ten' );
$pairs->set( 100 => 'hundred' );
is( Dumper($pairs), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}], 'Data::Pairs' )",
    "set(), ordering 'sd'" );

$pairs->add( 1 => 'one' );
is( Dumper($pairs), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}], 'Data::Pairs' )",
    "add(), ordering 'sd'" );

$pairs->clear();
Data::Pairs->order( 'nd' );  # number descending

$pairs->set( 2   => 'two' );
$pairs->set( 10  => 'ten' );
$pairs->set( 100 => 'hundred' );
is( Dumper($pairs), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Pairs' )",
    "set(), ordering 'nd'" );

$pairs->add( 1 => 'one' );
is( Dumper($pairs), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}], 'Data::Pairs' )",
    "add(), ordering 'nd'" );

$pairs->clear();
Data::Pairs->order( 'sna' );  # string/number ascending
$pairs->set( z => 26 );
$pairs->set( y => 25 );
$pairs->add( x => 24 );  # set and add are the same for new key/value members
$pairs->set( 100 => 'hundred' );
$pairs->set( 10  => 'ten' );
$pairs->add( 2   => 'two' );
is( Dumper($pairs), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Pairs' )",
    "set()/add(), ordering 'sna'" );

$pairs->clear();
Data::Pairs->order( 'snd' );  # string/number descending
$pairs->add( x => 24 );  # set and add are the same for new key/value members
$pairs->set( y => 25 );
$pairs->set( z => 26 );
$pairs->add( 2   => 'two' );
$pairs->set( 10  => 'ten' );
$pairs->set( 100 => 'hundred' );
is( Dumper($pairs), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Pairs' )",
    "set()/add(), ordering 'snd'" );

$pairs->clear();
Data::Pairs->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
$pairs->set( 550 => "note" );
$pairs->set( 500 => "note" );
$pairs->set( 510 => "note" );
$pairs->set( 650 => "subj" );
$pairs->set( 600 => "subj" );
$pairs->set( 610 => "subj" );
$pairs->set( 245 => "title" );
$pairs->set( 100 => "author" );
is( Dumper($pairs), "bless( [{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}], 'Data::Pairs' )",
    "set(), custom ordering" );

