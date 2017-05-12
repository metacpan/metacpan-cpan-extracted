#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use BSON::Decode;
plan tests => 4;

my $bson;
{
    open( my $INF, glob './t/test1.bson' );
    local $/ = undef;
    $bson = <$INF>;
    close $INF;
}
my $data1_exp = {
    'string'        => 'test',
    'creation_time' => '1470557330535',
    'zip_code'      => '06852',
    'double'        => '1',
    '_id'           => '57a6ec92e3500f4aa5178096'
};

my $data2_exp = {
    '_id'       => '57a6ec92e3500f4aa5178097',
    'timestamp' => '6315995639243080214',
    'string'    => 'Hello World',
    'regex'     => '/(\\d+)/im',
    'string_nr' => '01234',
    'hidden'    => 0
};

my $bs = BSON::Decode->new( $bson );

my $data1 = $bs->fetch();
is_deeply( $data1, $data1_exp, 'First element JSON' );

my $data2 = $bs->fetch();
is_deeply( $data2, $data2_exp, 'Second element JSON' );

$bs->rewind;
my $data1r = $bs->fetch();
is_deeply( $data1r, $data1_exp, 'First element JSON after rewind' );

$bs->rewind;
my $data_all = $bs->fetch_all();
is_deeply( $data_all, [$data1_exp, $data2_exp], 'First element JSON' );

