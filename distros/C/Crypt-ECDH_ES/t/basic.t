#! perl

use strict;
use warnings;

use Test::More;

use Crypt::ECDH_ES ':all';

my $original = 'Blabla';

my $ciphertext = ecdhes_encrypt(pack('H*', '87558542bbbfff0f93902ffa8434b44235daa830ccffb1a6b5300b3cda701d05'), $original);
is(length($ciphertext), 1 + 1 + 32 + 2 + 32 + 4 + 16 * int(length($original) / 16 + 1));

my $plaintext = ecdhes_decrypt(pack('Cx31', 42), $ciphertext);

is($plaintext, $original, 'decrypted ciphertext is identical to original');

done_testing;
