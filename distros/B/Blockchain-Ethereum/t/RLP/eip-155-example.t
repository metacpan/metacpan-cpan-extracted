#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::RLP;

subtest "eip-155 example" => sub {
    my $rlp = Blockchain::Ethereum::RLP->new();

    # unsigned
    my $params  = ['0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535', '0xde0b6b3a7640000', '0x', '0x1', '0x', '0x'];
    my $encoded = $rlp->encode($params);

    is(
        unpack("H*", $encoded),
        'ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080',
        'encoding for unsigned transaction ok'
    );

    my $decoded = $rlp->decode($encoded);

    is_deeply($params, $decoded, 'decoding for unsigned transaction ok');

    #signed
    $params = [
        '0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535',
        '0xde0b6b3a7640000', '0x', '0x25',
        '0x28ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276',
        '0x67cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83'
    ];

    $encoded = $rlp->encode($params);

    is(
        unpack("H*", $encoded),
        'f86c098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a76400008025a028ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276a067cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83',
        'encoding for signed transaction ok'
    );

    $decoded = $rlp->decode($encoded);

    is_deeply($params, $decoded, 'decoding for signed transaction ok');
};

done_testing;
