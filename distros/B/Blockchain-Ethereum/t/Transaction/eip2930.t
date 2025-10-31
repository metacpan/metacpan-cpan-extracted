#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::Transaction::EIP2930;
use Blockchain::Ethereum::Keystore::Key;
use Blockchain::Ethereum::Utils;

# These tests are based on the result of running the same transactions over ethers.js

subtest 'no access list' => sub {
    my $transaction = Blockchain::Ethereum::Transaction::EIP2930->new(
        chain_id  => '0x1',
        nonce     => '0x0',
        gas_price => '0x4A817C800',
        gas_limit => '0x5208',
        to        => '0x3535353535353535353535353535353535353535',
        value     => parse_units('1', ETH),
        data      => '0x',
    );

    my $key = Blockchain::Ethereum::Keystore::Key->new(
        private_key => pack "H*",
        '4646464646464646464646464646464646464646464646464646464646464646'
    );

    $key->sign_transaction($transaction);

    my $raw_transaction = $transaction->serialize;

    is unpack("H*", $raw_transaction),
        '01f86e01808504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080c001a00cbb47e86ca4f83d9675eccb8ea3c7f1f4718ab998baa4083c3627353c293103a064eba85277a343804e99ee028783fe90d05b3994202a0b77c8b04fb089fbc07a';
};

subtest 'with access list' => sub {
    my $transaction = Blockchain::Ethereum::Transaction::EIP2930->new(
        chain_id    => '0x1',
        nonce       => '0x1',
        gas_price   => '0x4A817C800',
        gas_limit   => '0xC350',
        to          => '0x1234567890123456789012345678901234567890',
        value       => '0x0',
        data        => '0x',
        access_list => [{
                address      => '0x1234567890123456789012345678901234567890',
                storage_keys => [
                    '0x0000000000000000000000000000000000000000000000000000000000000001',
                    '0x0000000000000000000000000000000000000000000000000000000000000002'
                ]
            },
            {
                address      => '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
                storage_keys => ['0x0000000000000000000000000000000000000000000000000000000000000003']}
        ],
    );

    my $key = Blockchain::Ethereum::Keystore::Key->new(
        private_key => pack "H*",
        '4646464646464646464646464646464646464646464646464646464646464646'
    );

    $key->sign_transaction($transaction);

    my $raw_transaction = $transaction->serialize;

    is unpack("H*", $raw_transaction),
        '01f8fa01018504a817c80082c3509412345678901234567890123456789012345678908080f893f859941234567890123456789012345678901234567890f842a00000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000002f794abcdefabcdefabcdefabcdefabcdefabcdefabcde1a0000000000000000000000000000000000000000000000000000000000000000380a0d7244e5c53f061d5b93c91f8b87e8d92c597a2caa0566da54da00d02618445bda07f54f05993af2dcd5f6fe606eee54ef29f9223931af5924a67febf612f9e3446';
};

subtest 'access list encoding' => sub {
    my $tx = Blockchain::Ethereum::Transaction::EIP2930->new(
        nonce       => '0x0',
        gas_price   => '0x4A817C800',
        gas_limit   => '0x5208',
        to          => '0x3535353535353535353535353535353535353535',
        value       => parse_units('1', ETH),
        chain_id    => '0x1',
        data        => '0x',
        access_list => [{
                address      => '0x1234567890123456789012345678901234567890',
                storage_keys => [
                    '0x0000000000000000000000000000000000000000000000000000000000000001',
                    '0x0000000000000000000000000000000000000000000000000000000000000002'
                ]}
        ],
    );

    my $encoded  = $tx->_encode_access_list;
    my $expected = [[
            '0x1234567890123456789012345678901234567890',
            [
                '0x0000000000000000000000000000000000000000000000000000000000000001',
                '0x0000000000000000000000000000000000000000000000000000000000000002'
            ]]];

    is_deeply $encoded, $expected, 'correct access list encoding';

    # Test empty access list
    $tx = Blockchain::Ethereum::Transaction::EIP2930->new(
        nonce     => '0x0',
        gas_price => '0x4A817C800',
        gas_limit => '0x5208',
        to        => '0x3535353535353535353535353535353535353535',
        value     => parse_units('1', ETH),
        chain_id  => '0x1',
        data      => '0x',
    );

    is_deeply $tx->_encode_access_list, [], 'correct empty access list encoding';
};

done_testing;
