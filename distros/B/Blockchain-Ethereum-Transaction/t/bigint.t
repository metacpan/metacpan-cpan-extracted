#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Blockchain::Ethereum::Transaction::EIP1559;
use Math::BigInt;

subtest "Math::BigInt explicit" => sub {
    my $transaction = Blockchain::Ethereum::Transaction::EIP1559->new(
        nonce                    => Math::BigInt->new(1),
        max_fee_per_gas          => Math::BigInt->new(9),
        max_priority_fee_per_gas => Math::BigInt->bzero(),
        gas_limit                => Math::BigInt->new(21000),
        to                       => Math::BigInt->from_hex('0x3535353535353535353535353535353535353535'),
        value                    => Math::BigInt->new('1000000000000000000'),
        chain_id                 => Math::BigInt->new(1337),
    );

    is unpack("H*", $transaction->serialize), "02e9820539018009825208943535353535353535353535353535353535353535880de0b6b3a764000080c0";
};

subtest "use bigint" => sub {
    use bigint;
    my $transaction = Blockchain::Ethereum::Transaction::EIP1559->new(
        nonce                    => 1,
        max_fee_per_gas          => 9,
        max_priority_fee_per_gas => 0,
        gas_limit                => 21000,
        to                       => '0x3535353535353535353535353535353535353535',
        value                    => 1000000000000000000,
        chain_id                 => 1337,
    );

    no bigint;
    is unpack("H*", $transaction->serialize), "02e9820539018009825208943535353535353535353535353535353535353535880de0b6b3a764000080c0";
};

done_testing;
