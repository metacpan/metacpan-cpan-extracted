#! perl

use strict;
use warnings;

use Test::More;

use Crypt::Bear::RSA;
use Crypt::Bear::Hash;
use Crypt::Bear::HMAC::DRBG;

my $prng = Crypt::Bear::HMAC::DRBG->new('sha256', 'BearSSL test');
$prng->system_seed;

my ($public, $private) = Crypt::Bear::RSA::generate_keypair($prng, 1024);
ok $public;
ok $private;

my $payload = "ABCDEFG";
my $ciphertext = $public->oaep_encrypt('sha256', $payload, $prng, 'Label');
my $plaintext = $private->oaep_decrypt('sha256', $ciphertext, 'Label');
is($plaintext, $payload);

my $digest = 'sha256';
my $digester = Crypt::Bear::Hash->new($digest);
$digester->update($payload);
my $hash = $digester->out;

my $signature = $private->pkcs1_sign($digest, $hash);
my $hashed = $public->pkcs1_verify($digest, $signature);
is $hashed, $hash;

done_testing;
