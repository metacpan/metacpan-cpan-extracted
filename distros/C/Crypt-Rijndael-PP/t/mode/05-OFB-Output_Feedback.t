#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::Crypt::Rijndael qw( test_rijndael_pp_encryption_and_decryption );
use Test::Crypt::Rijndael::Constant qw(
    $DEFAULT_IV
    $INPUT_BLOCKS
    $KEYS
    $CIPHER_TEXT
);

use Crypt::Rijndael::PP;

subtest 'Encryption with 128 Bit Key' => sub {
    for my $num_blocks ( 1, 2, 3 ) {
        subtest "$num_blocks Blocks" => sub {
            test_rijndael_pp_encryption_and_decryption(
                key   => $KEYS->{128},
                mode  => 'MODE_OFB',
                iv    => $DEFAULT_IV,
                plain_text  => $INPUT_BLOCKS->{$num_blocks},
                cipher_text => $CIPHER_TEXT->{OFB}{$num_blocks}{128},
            );
        };
    }
};

subtest 'Encryption with 192 Bit Key' => sub {
    for my $num_blocks ( 1, 2, 3 ) {
        subtest "$num_blocks Blocks" => sub {
            test_rijndael_pp_encryption_and_decryption(
                key   => $KEYS->{192},
                mode  => 'MODE_OFB',
                iv    => $DEFAULT_IV,
                plain_text  => $INPUT_BLOCKS->{$num_blocks},
                cipher_text => $CIPHER_TEXT->{OFB}{$num_blocks}{192},
            );
        };
    }
};

subtest 'Encryption with 256 Bit Key' => sub {
    for my $num_blocks ( 1, 2, 3 ) {
        subtest "$num_blocks Blocks" => sub {
            test_rijndael_pp_encryption_and_decryption(
                key   => $KEYS->{256},
                mode  => 'MODE_OFB',
                iv    => $DEFAULT_IV,
                plain_text  => $INPUT_BLOCKS->{$num_blocks},
                cipher_text => $CIPHER_TEXT->{OFB}{$num_blocks}{256},
            );
        };
    }
};

done_testing;
