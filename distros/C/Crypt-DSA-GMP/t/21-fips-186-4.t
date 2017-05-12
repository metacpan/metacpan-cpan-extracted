#!/usr/bin/env perl
use strict;
use warnings;

# I don't know of any 186-4 test vectors, so these are made up.

use Test::More;
use Crypt::DSA::GMP;
use Crypt::DSA::GMP::KeyChain;

plan tests => 9;

my $start_seed = pack("H*", "2b7ee949b8c203b69feff0fc40ad05e66d062c023d1a1f36746db18ce72aec92");
my $expected_p = Math::BigInt->from_hex("0xa3daef0dca554ff0dde95212079ab455710d95312d0eef2a7bd9c729b475773315c2ce8c648604b28321da03ae3c659d666bac2f90e70ae86692b13f7ff232ebc3d10ff6dbfc10137c6d2fd4ed78cd50780e4eed753c2e2f047a4111a59471cccf2ff9f0f77c5a442ea15d6188a9b702450363e015fb64b71c0b4ab0bda89727333c0e37c121af18e61446d53697a65d33651f28199587ff7f20699946b0c4a8a6231715e67c4a9893194dc5465fbe9ebab35d834d18f41f5254d87787cbae029351a0f38d4dd820eb6ec6d8daefa11c3da13dd9e940b1192b447f8608091c77a1ddf729b823c6108416cf3287c01e738672b7459423c490b6861868c5ac1e3d");
my $expected_q = Math::BigInt->from_hex("0xfca36e9e6c0b3dc4153ee95d7fdbaf702a4d623c18bcc764a62f17903079aced");
my $expected_g = Math::BigInt->from_hex("0xc571d81cf3fe9f8946dddd1e511a0958003b7a88478ac55ecfd26c96dad0983895fc8c8f4783826db04c2d774b4ae3a2376980d137a5993f62c7a86a36cccad2f5d2dd9367ddbeb69352e32d5e078e0d6f76a2022e2999b3b9012566dd66f13cc1c929387084412f5dc97f198977ac95fff6005cd8d3959b5936bf51db93ca35c3d0e08dda2e83eb57974b8e8c7fb37cc0e6b12fa1af88d3ad2d16602821c7302b7f1e6d1e89f75843789203a353e28e284504e7f4147aad359933d2599abb9b2821cc164016f9458d29ce6bc281da04342f978d45d9d2818c44de1dd48dd482fbede9d2560481f66745520760bc655152d28bb1e5e2488f75e4cb3f3baa619");

my $dsa = Crypt::DSA::GMP->new( Standard => "FIPS 186-4" );
ok($dsa, 'Crypt::DSA::GMP->new worked');

my $keychain = Crypt::DSA::GMP::KeyChain->new( Standard => "FIPS 186-4" );
ok($keychain, 'Crypt::DSA::GMP::KeyChain->new worked');

## generate_params builds p, q, and g.
my($key, $counter, $h, $seed) = $keychain->generate_params(
	Size => 2048,
	Seed => $start_seed,
);
is($key->p, $expected_p, '->p returns expected value');
is($key->q, $expected_q, '->q returns expected value');
is($key->g, $expected_g, '->g returns expected value');

is($counter, 63, 'Consistency check 1');
is($h, 2, 'Consistency check 2');
is($seed, $start_seed, 'Consistency check 3');

## Generate random public and private keys.
$keychain->generate_keys($key, 1);  # Turn on nonblocking for testing

my $str1 = "12345678901234567890";

## Test key generation by signing and verifying a message.
my $sig = $dsa->sign(Message => $str1, Key => $key);
ok($dsa->verify(Message => $str1, Key => $key, Signature => $sig), 'Signing and verifying ok');
