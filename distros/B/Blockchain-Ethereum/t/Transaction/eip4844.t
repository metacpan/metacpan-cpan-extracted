#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Blockchain::Ethereum::Key;
use Blockchain::Ethereum::Transaction::EIP4844;

# These tests are based on the result of running the same transactions over ethers.js

subtest 'single blob' => sub {
    my $tx = Blockchain::Ethereum::Transaction::EIP4844->new(
        chain_id                 => '0x1',
        nonce                    => '0x0',
        max_priority_fee_per_gas => '0x77359400',                                                             # 2 gwei
        max_fee_per_gas          => '0x4a817c800',                                                            # 20 gwei
        max_fee_per_blob_gas     => '0x3b9aca00',                                                             # 1 gwei
        gas_limit                => '0x186a0',                                                                # 100000
        to                       => '0x1234567890123456789012345678901234567890',
        value                    => '0x16345785d8a0000',                                                      # 0.1 ETH
        data                     => '0xdeadbeef',
        blob_versioned_hashes    => ['0x010657f37554c781402a22917dee2f75def7ab966d7b770905398eba3c444014'],
    );

    my $key = Blockchain::Ethereum::Key->new(
        private_key => pack "H*",
        '4646464646464646464646464646464646464646464646464646464646464646'
    );

    $key->sign_transaction($tx);

    my $raw_transaction = $tx->serialize;

    is unpack("H*", $raw_transaction),
        '03f89f018084773594008504a817c800830186a094123456789012345678901234567890123456789088016345785d8a000084deadbeefc0843b9aca00e1a0010657f37554c781402a22917dee2f75def7ab966d7b770905398eba3c44401401a0766af62f60f5aab78cf270654e9bd5c0cc323ddf06b9cd561e6d039506e74527a045b9cd65d3cf84b8464fd6012db1bafab1167c7030f5bf08c8562cf8e47cde5c',
        'single blob transaction serialization matches';

    my $expected_hash = pack("H*", '8baba8257fc22d312341b8790f1f838da417ed8e0846b11e7ef311643a1bb2b0');
    is $tx->hash, $expected_hash, 'single blob transaction hash matches';
};

subtest 'multiple blobs with access list' => sub {
    my $tx = Blockchain::Ethereum::Transaction::EIP4844->new(
        chain_id                 => '0x539',                                        # 1337
        nonce                    => '0x1',
        max_priority_fee_per_gas => '0xb2d05e00',                                   # 3 gwei
        max_fee_per_gas          => '0x5d21dba00',                                  # 25 gwei
        max_fee_per_blob_gas     => '0x77359400',                                   # 2 gwei
        gas_limit                => '0x249f0',                                      # 150000
        to                       => '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
        value                    => '0x0',
        data                     => '0x',
        access_list              => [{
                address      => '0x1234567890123456789012345678901234567890',
                storage_keys => ['0x0000000000000000000000000000000000000000000000000000000000000001']}
        ],
        blob_versioned_hashes => [
            '0x010657f37554c781402a22917dee2f75def7ab966d7b770905398eba3c444014',
            '0x01ac9710ba11d0d3cbea6d499ddc888c02f3374c2336331f3e11b33260054aeb',
            '0x0157374c17c7f992ec8fbcaaa1deffdb77914dad0bf6b9d7015dd7b86ccbd253'
        ],
    );

    my $key = Blockchain::Ethereum::Key->new(
        private_key => pack "H*",
        '4646464646464646464646464646464646464646464646464646464646464646'
    );

    $key->sign_transaction($tx);

    my $raw_transaction = $tx->serialize;

    is unpack("H*", $raw_transaction),
        '03f901118205390184b2d05e008505d21dba00830249f094abcdefabcdefabcdefabcdefabcdefabcdefabcd8080f838f7941234567890123456789012345678901234567890e1a000000000000000000000000000000000000000000000000000000000000000018477359400f863a0010657f37554c781402a22917dee2f75def7ab966d7b770905398eba3c444014a001ac9710ba11d0d3cbea6d499ddc888c02f3374c2336331f3e11b33260054aeba00157374c17c7f992ec8fbcaaa1deffdb77914dad0bf6b9d7015dd7b86ccbd25301a003174860c819e69bf4ddb29ccd9807ecb592954379e049233604d3078c81e2afa0713e1ea8433600ad78d7b1b3ecd65673667a5ca231003869c31828eb1799508d',
        'multiple blobs with access list transaction serialization matches';

    my $expected_hash = pack("H*", 'd917fca233a984f1680898f0c0548657bd7cc46e313c18768bf60f7fb7554c3d');
    is $tx->hash, $expected_hash, 'multiple blobs transaction hash matches';
};

done_testing;
