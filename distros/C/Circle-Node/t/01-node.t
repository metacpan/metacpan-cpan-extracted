#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Carp;
use JSON;
use Try::Tiny;
use Circle::Node;

my $response = subscribe();
is( $response->{status}, 200 );
my $data = $response->{data};
ok($data);

$response = serverFeatures();
is( $response->{status}, 200 );
$data = $response->{data};
ok($data);

$response = broadcastTransaction(
    {
        txid     => '',
        type     => 0,
        hash     => '',
        version  => 1,
        size     => 100,
        vsize    => 100,
        weight   => 0,
        locktime => 0,
        vin      => [
            {
                txid      => '',
                vout      => 0,
                scriptSig => {
                    asm => '',
                    hex => '',
                },
                txinwitness => [],
                sequence    => 0,
                addresses   => [''],
                value       => '',
            }
        ],
        vout => [
            {
                value        => '',
                n            => 0,
                scriptPubKey => '',
            }
        ],
        blockhash     => '',
        confirmations => 1,
        time          => 1725885098000,
        blocktime     => 1725887098000
    }
);

isnt( $response->{status}, 200 );
$data = $response->{data};
carp(encode_json($response));

done_testing();
