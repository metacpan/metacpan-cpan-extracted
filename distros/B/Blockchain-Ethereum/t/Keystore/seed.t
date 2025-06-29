#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::Keystore::Seed;

subtest "mnemonic" => sub {
    my $mnemonic = "render fence burst reward finger disorder peanut novel flush solution torch permit ready boost void";
    my $seed     = Blockchain::Ethereum::Keystore::Seed->new(mnemonic => $mnemonic);

    is $seed->derive_key(0)->address,   '0xEE7df9e883cDD6ed5686E70E684a9D7dd31Cf090';
    is $seed->derive_key(100)->address, '0xcAccf9f7F73a64FCcD6cf35974E4E55C1a4585cC';
    is $seed->derive_key(808)->address, '0x3Fe056f928882E83b88408A55F0DCa5536B3356B';
};

subtest "seed" => sub {
    my $vseed = pack "H*",
        "2822943239a891aa712b4b4c3ac5667c57d789b9606cb200ebd03cb4fe1be39a9eb8853154429c6e7c3ba958faaa5618b0ffcebca14d063db99d52716e1970fe";
    my $seed = Blockchain::Ethereum::Keystore::Seed->new(seed => $vseed);

    is $seed->derive_key(0)->address,   '0xEE7df9e883cDD6ed5686E70E684a9D7dd31Cf090';
    is $seed->derive_key(100)->address, '0xcAccf9f7F73a64FCcD6cf35974E4E55C1a4585cC';
    is $seed->derive_key(808)->address, '0x3Fe056f928882E83b88408A55F0DCa5536B3356B';
};

subtest "new seed" => sub {
    my $seed = Blockchain::Ethereum::Keystore::Seed->new();
    ok $seed->derive_key(0)->address;
};

done_testing();
