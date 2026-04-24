use strict;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;

# Tests for sign/verify edge cases not covered by rsa.t or padding.t:
# cross-hash verification, empty messages, and malformed signatures.

plan tests => 7;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);
my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($rsa->get_public_key_string());

# --- Cross-hash verification ---
# Sign with one hash, verify with another — should always fail.

# sha256 sign, sha1 verify
{
    $rsa->use_sha256_hash();
    $rsa->use_pkcs1_pss_padding();
    my $msg = "cross-hash test message";
    my $sig = $rsa->sign($msg);

    # SHA1 verify may croak on systems with legacy digest restrictions (e.g. almalinux:9)
    $rsa_pub->use_sha1_hash();
    $rsa_pub->use_pkcs1_pss_padding();
    my $result = eval { $rsa_pub->verify($msg, $sig) };
    ok(!$result, "sha256 signature does not verify with sha1 hash");
}

# sha1 sign, sha256 verify — SHA1 signing may be disabled on FIPS-like systems
SKIP: {
    $rsa->use_sha1_hash();
    $rsa->use_pkcs1_pss_padding();
    my $msg = "reverse cross-hash test";
    my $sig = eval { $rsa->sign($msg) };
    skip "SHA1 signing not available: $@", 1 if $@;

    $rsa_pub->use_sha256_hash();
    $rsa_pub->use_pkcs1_pss_padding();
    my $result = eval { $rsa_pub->verify($msg, $sig) };
    ok(!$result, "sha1 signature does not verify with sha256 hash");
}

# --- Empty message ---

{
    $rsa->use_sha256_hash();
    $rsa->use_pkcs1_pss_padding();
    $rsa_pub->use_sha256_hash();
    $rsa_pub->use_pkcs1_pss_padding();

    my $sig = $rsa->sign("");
    ok(defined $sig && length($sig) > 0,
        "signing empty message produces a non-empty signature");

    ok($rsa_pub->verify("", $sig),
        "empty message signature verifies correctly");

    ok(!$rsa_pub->verify("not empty", $sig),
        "empty message signature does not verify different message");
}

# --- Malformed signatures ---

{
    $rsa_pub->use_sha256_hash();
    $rsa_pub->use_pkcs1_pss_padding();

    # Empty string as signature
    my $result = eval { $rsa_pub->verify("test", "") };
    ok(!$result || $@,
        "verify with empty signature returns false or croaks");

    # Single-byte signature
    $result = eval { $rsa_pub->verify("test", "\x00") };
    ok(!$result || $@,
        "verify with 1-byte signature returns false or croaks");
}
