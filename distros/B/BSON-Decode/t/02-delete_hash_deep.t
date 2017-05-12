###!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

#use lib '/home/fabrice/T_D/Devel/BSON-Decode/lib';
use BSON::Decode;
plan tests => 2;

my @skip  = ( '^_id$', '^t\d', '^timestamp$' );
my $codec = BSON::Decode->new('./t/test2.bson');
my $data1 = [
    {
        'hash' => {
            'i' => 'hi',
            'h' => {
                's' => 's1',
                'u' => [ 'p', 'q' ],
                't' => 't1'
            }
        },
        'creation_time' => '1470726113082',
        'other'         => {
            'test' => 'truc'
        },
        'int32' => 42,
        'arr'   => [
            'a', 'b', 'c',
            {},
            [
                'w', 'x',
                {
                    'y' => 'toto'
                }
            ]
        ],
        'string_nr' => '01234',
        'string'    => 'Hello World',
        'hidden'    => 0,
        'zip_code'  => '06852',
        'nohidden'  => 1,
        'machin'    => [ {}, {}, {} ]
    }
];
my $data2 = [
    {
        'other' => {
            'test' => 'truc'
        },
        'string'        => 'Hello World',
        'string_nr'     => '01234',
        'nohidden'      => 1,
        'creation_time' => '1470726113082',
        'int32'         => 42,
        'hidden'        => 0,
        'hash'          => {
            'h' => {
                'u' => [ 'p', 'q' ],
                't' => 't1',
                's' => 's1'
            },
            'i' => 'hi'
        },
        'zip_code' => '06852',
        'arr'      => [
            'a', 'b', 'c', undef,
            [
                'w', 'x',
                {
                    'y' => 'toto'
                }
            ]
        ]
    }
];

my $bson = $codec->fetch_all();
BSON::Decode::delete_hash_deep( $bson, \@skip );
is_deeply( $bson, $data1, 'Delete key without clean' );

$codec->rewind();
$bson = $codec->fetch_all();
BSON::Decode::delete_hash_deep( $bson, \@skip, 1 );
is_deeply( $bson, $data2, 'Delete key with clean' );
