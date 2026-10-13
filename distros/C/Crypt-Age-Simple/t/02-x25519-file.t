#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw< tempfile >;

use Crypt::Age::Simple qw< :x25519 >;

can_ok __PACKAGE__, qw< age_x25519_decrypt age_x25519_encrypt  >;

my ($public, $secret) = age_x25519_generate_keypair();
my $cleartext = 'foo that bar!';

my @ciphertexts;

# this is on the gray-corner side, making sure that an undefined output
# means that the stuff is given back as a string.
lives_ok {
   push @ciphertexts, age_x25519_encrypt_file($public, \$cleartext, undef);
} 'age_x25519_encrypt_file lives with straight public key';
ok length($ciphertexts[0]), 'generated some ciphertext';

my $outcome;
lives_ok {
   my $output = '';
   $outcome = age_x25519_encrypt_file([$public], \$cleartext, \$output);
   push @ciphertexts, $output;
} 'age_x25519_encrypt_file lives with arrayref of public key(s)';
is $outcome, 1, 'return value as expected';
ok length($ciphertexts[1]), 'generated some ciphertext';

for my $ciphertext (@ciphertexts) {
   for my $test (
         [ 'straight identity' => $secret], 
         [ 'arrayref of identities' => [$secret] ]
      )
   {
      my ($msg, $id) = $test->@*;
      my $decoded;
      lives_ok { age_x25519_decrypt_file($id, \$ciphertext, \$decoded) }
         "age_x25519_decrypt lives with $msg";
      is $decoded, $cleartext, 'decryption was successful';
   }
}

my ($ifh, $original) = tempfile(UNLINK => 1);
my (undef, $encrypted) = tempfile(UNLINK => 1);
my (undef, $decrypted) = tempfile(UNLINK => 1);

binmode $ifh, ':raw';
print {$ifh} $cleartext;
close $ifh;

lives_ok { age_x25519_encrypt_file([$public], $original, $encrypted) }
   'encrypt to file';
ok -s $encrypted, 'encrypted file was generated';

lives_ok { age_x25519_decrypt_file($secret, $encrypted, $decrypted) }
   'decrypt to file';
ok -s $decrypted, 'decrypted file was generated';

my $retrieved = do { local(@ARGV, $/) = $decrypted; <> };
is $retrieved, $cleartext, 'decryption was successful across files';

done_testing();
