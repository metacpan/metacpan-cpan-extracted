use strict;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Guess qw(openssl_version);

my ($major) = openssl_version;

if ($major lt '3.0') {
    plan skip_all => 'PSS auto-promote only applies to OpenSSL 3.x';
}

plan tests => 6;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);
my $pub_key_str = $rsa->get_public_key_string();
my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($pub_key_str);

my $plaintext = "The quick brown fox jumped over the lazy dog";

# Test 1-2: OAEP auto-promotes to PSS for signing — basic round-trip
# When OAEP is set, sign() auto-promotes to PSS internally.
# The bug: mgf1_md and saltlen are NOT configured for the auto-promoted case
# because the check uses p_rsa->padding (still OAEP) instead of sign_pad (PSS).
$rsa->use_pkcs1_oaep_padding;
$rsa->use_sha256_hash;
$rsa_pub->use_pkcs1_oaep_padding;
$rsa_pub->use_sha256_hash;

my $sig_oaep = $rsa->sign($plaintext);
ok(defined $sig_oaep, "sign with OAEP padding succeeds (auto-promotes to PSS)");
ok($rsa_pub->verify($plaintext, $sig_oaep),
   "verify with OAEP padding matches (both use same auto-promoted params)");

# Test 3-4: Cross-verification — sign with OAEP, verify with explicit PSS
# This is the real test. If mgf1/saltlen setup is skipped for auto-promoted PSS,
# the signature uses OpenSSL defaults (MGF1=SHA-1, saltlen=max).
# Explicit PSS sets MGF1=SHA-256, saltlen=digest_length.
# With the bug, these differ — cross-verification fails.
$rsa->use_pkcs1_oaep_padding;
$rsa->use_sha256_hash;
my $sig_from_oaep = $rsa->sign($plaintext);
ok(defined $sig_from_oaep, "sign with OAEP+SHA256 produces signature");

$rsa_pub->use_pkcs1_pss_padding;
$rsa_pub->use_sha256_hash;
ok($rsa_pub->verify($plaintext, $sig_from_oaep),
   "OAEP-signed message verifies with explicit PSS (mgf1/saltlen must match)");

# Test 5-6: Reverse — sign with explicit PSS, verify with OAEP (auto-promoted)
$rsa->use_pkcs1_pss_padding;
$rsa->use_sha256_hash;
my $sig_from_pss = $rsa->sign($plaintext);
ok(defined $sig_from_pss, "sign with explicit PSS+SHA256 produces signature");

$rsa_pub->use_pkcs1_oaep_padding;
$rsa_pub->use_sha256_hash;
ok($rsa_pub->verify($plaintext, $sig_from_pss),
   "PSS-signed message verifies with OAEP padding (auto-promoted PSS must match)");
