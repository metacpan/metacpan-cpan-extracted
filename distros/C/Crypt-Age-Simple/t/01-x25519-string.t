#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Crypt::Age::Simple qw< :x25519 >;

can_ok __PACKAGE__, qw< age_x25519_decrypt age_x25519_encrypt  >;

my ($public, $secret) = age_x25519_generate_keypair();
my $cleartext = 'foo that bar!';

my @ciphertexts;
lives_ok { push @ciphertexts, age_x25519_encrypt($public, $cleartext) }
   'age_x25519_encrypt lives with straight public key';
ok length($ciphertexts[0]), 'generated some ciphertext';

lives_ok { push @ciphertexts, age_x25519_encrypt([$public], $cleartext) }
   'age_x25519_encrypt lives with arrayref of public key(s)';
ok length($ciphertexts[1]), 'generated some ciphertext';

for my $ciphertext (@ciphertexts) {
   for my $test (
         [ 'straight identity' => $secret], 
         [ 'arrayref of identities' => [$secret] ]
      )
   {
      my ($msg, $id) = $test->@*;
      my $decoded;
      lives_ok { $decoded = age_x25519_decrypt($id, $ciphertext) }
         "age_x25519_decrypt lives with $msg";
      is $decoded, $cleartext, 'decryption was successful';
   }
}

done_testing();
