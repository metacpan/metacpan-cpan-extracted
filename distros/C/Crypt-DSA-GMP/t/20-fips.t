#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Crypt::DSA::GMP;
use Crypt::DSA::GMP::KeyChain;

plan tests => 9;

# FIPS 186-2 Appendix 5 test vector for DSA (L=512, N=160) and SHA-1.
my $start_seed = pack("H*", "d5014e4b60ef2ba8b6211b4062ba3224e0427dd3");
my $expected_p = Math::BigInt->from_hex("0x8df2a494492276aa3d25759bb06869cbeac0d83afb8d0cf7cbb8324f0d7882e5d0762fc5b7210eafc2e9adac32ab7aac49693dfbf83724c2ec0736ee31c80291");
my $expected_q = Math::BigInt->from_hex("0xc773218c737ec8ee993b4f2ded30f48edace915f");
my $expected_g = Math::BigInt->from_hex("0x626d027839ea0a13413163a55b4cb500299d5522956cefcb3bff10f399ce2c2e71cb9de5fa24babf58e5b79521925c9cc42e9f6f464b088cc572af53e6d78802");

## We'll need this later to sign and verify.
my $dsa = Crypt::DSA::GMP->new;
ok($dsa, 'Crypt::DSA::GMP->new worked');

## Create a keychain to generate our keys. Generally you
## don't need to be this explicit (just call keygen), but if
## you want the extra state data (counter, h, seed) you need
## to use the actual methods themselves.
my $keychain = Crypt::DSA::GMP::KeyChain->new;
ok($keychain, 'Crypt::DSA::GMP::KeyChain->new worked');

## generate_params builds p, q, and g.
my($key, $counter, $h, $seed) = $keychain->generate_params(
	Size => 512,
	Seed => $start_seed,
);
is($key->p, $expected_p, '->p returns expected value');
is($key->q, $expected_q, '->q returns expected value');
is($key->g, $expected_g, '->g returns expected value');

# Counter = 105 (page 23)
# h = 2 (page 23)
# We should have found q with the start seed.
is($counter, 105, 'Consistency check 1');
is($h, 2, 'Consistency check 2');
is($seed, $start_seed, 'Consistency check 3');

## Generate random public and private keys.
$keychain->generate_keys($key, 1);  # Turn on nonblocking for testing

my $str1 = "12345678901234567890";

## Test key generation by signing and verifying a message.
my $sig = $dsa->sign(Message => $str1, Key => $key);
ok($dsa->verify(Message => $str1, Key => $key, Signature => $sig), 'Signing and verifying ok');
