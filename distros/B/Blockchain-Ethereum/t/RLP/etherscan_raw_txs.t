#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::RLP;
my $rlp = Blockchain::Ethereum::RLP->new();

# https://etherscan.io/tx/0x784412e6b8ce1e6fcce97d149dea5367a594aef61d6d328398fffac0bb3ab537
subtest "etherscan raw tx => tether transfer" => sub {
    # 0x02 removed from raw tx since the transaction type is not part of the RLP encoding
    my $raw_tx =
        'f8b3018305c6c98405f5e100851d4adefbd882fde894dac17f958d2ee523a2206206994597c13d831ec780b844a9059cbb000000000000000000000000f8dd85f9dae9caee1c3560284715e8933add0de70000000000000000000000000000000000000000000000000000000004c50220c080a0b55239aaa8b77ddb8982509ab2bffa71f7b6a313017e4c71c560b7cb57a01c58a03f9d03d40ded1c2978a81a1c3c566b830a6a2f884ba238d4c095190793b28d7c';
    my $tether_transfer = $rlp->decode(pack "H*", $raw_tx);

    my $decoded = [
        '0x1',                                                                   # nonce
        '0x5c6c9',                                                               # chain id
        '0x5f5e100',                                                             # max priority fee per gas
        '0x1d4adefbd8',                                                          # max base fee per gas
        '0xfde8',                                                                # gas limit
        '0xdac17f958d2ee523a2206206994597c13d831ec7',                            # tether contract
        '0x',                                                                    # value
        '0xa9059cbb000000000000000000000000f8dd85f9dae9caee1c3560284715e8933add0de70000000000000000000000000000000000000000000000000000000004c50220'
        ,                                                                        # data
        [],                                                                      # access list
        '0x',                                                                    # v
        '0xb55239aaa8b77ddb8982509ab2bffa71f7b6a313017e4c71c560b7cb57a01c58',    # r
        '0x3f9d03d40ded1c2978a81a1c3c566b830a6a2f884ba238d4c095190793b28d7c'     # s
    ];

    is_deeply $tether_transfer, $decoded;

    is unpack("H*", $rlp->encode($tether_transfer)), $raw_tx;
};

# https://etherscan.io/tx/0x85fdf30e7ce3884b0b6ae4955416bb1dc48eedeef11ed5e4ef8e185fc21b0f4e
subtest "etherscan raw tx => eth transfer" => sub {
    my $raw_tx =
        'f8730181ae8405f5e100850aa1b5e50382520894004af85ea96fd3771ed2e1df6f2b152bc81b47c087ce911cd5adbf7680c080a0e045e7d62f53c4bb03c330a17ba909936f783da5d04af2587fc2d1c48d7e7a15a05554e82b338819fcb288fc28fb1f685b1e84eb5c897bb1c4a4b62a7877c313e2';

    my $eth_transfer = $rlp->decode(pack "H*", $raw_tx);

    my $decoded = [
        '0x1',    #
        '0xae',
        '0x5f5e100',
        '0xaa1b5e503',
        '0x5208',
        '0x04af85ea96fd3771ed2e1df6f2b152bc81b47c0',
        '0xce911cd5adbf76',
        '0x',
        [],
        '0x',
        '0xe045e7d62f53c4bb03c330a17ba909936f783da5d04af2587fc2d1c48d7e7a15',
        '0x5554e82b338819fcb288fc28fb1f685b1e84eb5c897bb1c4a4b62a7877c313e2'
    ];

    is_deeply $eth_transfer, $decoded;

    is unpack("H*", $rlp->encode($eth_transfer)), $raw_tx;

};

done_testing;
