#! perl

use strict;
use warnings;

use Test::More;

use Crypt::Bear::Hash;
use Crypt::Bear::HMAC::DRBG;

my $prng = Crypt::Bear::HMAC::DRBG->new('sha256', 'BearSSL test');
$prng->system_seed;

my $private = Crypt::Bear::EC::PrivateKey->generate('secp256r1', $prng);
ok $private;

my $public = $private->public_key;
ok $public;

my $payload = "ABCDEFG";
my $digest = 'sha256';
my $digester = Crypt::Bear::Hash->new($digest);
$digester->update($payload);
my $hash = $digester->out;

my $signature = $private->ecdsa_sign($digest, $hash);
ok $signature;
ok $public->ecdsa_verify($digest, $hash, $signature);


my $private2 = Crypt::Bear::EC::PrivateKey->generate('secp256r1', $prng);
my $public2 = $private2->public_key;

my $left_side = $private->ecdh_key_exchange($public2);
my $right_side = $private2->ecdh_key_exchange($public);
is unpack("H*", $left_side), unpack("H*", $right_side);

done_testing;
