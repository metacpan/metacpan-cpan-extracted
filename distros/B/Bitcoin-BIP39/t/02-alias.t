#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Bitcoin::Mnemonic qw(
                            entropy_to_bip39_mnemonic
                            bip39_mnemonic_to_entropy
                            gen_bip39_mnemonic
                    );

subtest gen_bip39_mnemonic => sub {
    ok(gen_bip39_mnemonic());
};

DONE_TESTING:
done_testing;
