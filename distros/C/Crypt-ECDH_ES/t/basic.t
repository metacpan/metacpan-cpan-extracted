#! perl

use strict;
use warnings;

use Test::More;

use Crypt::ECDH_ES ':all';

my $plaintext = 'Blabla';

{
	my $ciphertext = ecdhes_encrypt(pack('H*', '87558542bbbfff0f93902ffa8434b44235daa830ccffb1a6b5300b3cda701d05'), $plaintext);
	is(length($ciphertext), 1 + 1 + 32 + 2 + 32 + 4 + 16 * int(length($plaintext) / 16 + 1));

	my $decrypted = ecdhes_decrypt(pack('Cx31', 42), $ciphertext);

	is($decrypted, $plaintext, 'decrypted ciphertext is identical to plaintext');
}

my ($a_public, $a_private) = ecdhes_generate_key;
my ($b_public, $b_private) = ecdhes_generate_key;

{
	my $ciphertext = ecdhes_encrypt_authenticated($b_public, $a_private, $plaintext);
	is(length($ciphertext), 2 + 1 + 32 + 1 + 32 + 1 + 32 + 4 + 16 * int(length($plaintext) / 16 + 1));

	my ($decrypted, $public) = ecdhes_decrypt_authenticated($b_private, $ciphertext);
	is($decrypted, $plaintext, 'decrypted ciphertext is identical to plaintext');
	is($public, $a_public);
}

done_testing;
