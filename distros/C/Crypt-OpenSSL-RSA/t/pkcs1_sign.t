use strict;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;

use Crypt::OpenSSL::Guess qw(openssl_version find_openssl_prefix find_openssl_exec);

my ($major, $minor, $patch) = openssl_version();
my $is_libressl = (`"@{[find_openssl_exec(find_openssl_prefix())]}" version` =~ /LibreSSL/);

# Regression tests for PKCS#1 v1.5 signing (RSASSA-PKCS1-v1_5).
# Issue #146: PKCS#1 v1.5 was disabled entirely in v0.35 to mitigate
# the Marvin attack, but the Marvin attack only affects decryption.
# PKCS#1 v1.5 signatures are secure and required by protocols like
# ACME/Let's Encrypt (RS256) and many JOSE/JWS implementations.

plan tests => 10;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);
my $pub_pem = $rsa->get_public_key_x509_string();
my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($pub_pem);

# --- use_pkcs1_padding() must not croak ---
eval { $rsa->use_pkcs1_padding() };
ok(!$@, "use_pkcs1_padding() does not croak");

# --- SHA-256 sign/verify (RS256 — used by ACME/Let's Encrypt) ---
{
    $rsa->use_pkcs1_padding();
    $rsa->use_sha256_hash();
    $rsa_pub->use_pkcs1_padding();
    $rsa_pub->use_sha256_hash();

    my $msg = '{"protected":"...","payload":"..."}';
    my $sig = $rsa->sign($msg);
    ok(defined $sig && length($sig) > 0,
       "PKCS#1 v1.5 + SHA-256 sign produces signature");

    ok($rsa_pub->verify($msg, $sig),
       "PKCS#1 v1.5 + SHA-256 signature verifies");

    ok(!$rsa_pub->verify("tampered", $sig),
       "PKCS#1 v1.5 + SHA-256 rejects tampered message");
}

# --- SHA-1 sign/verify (RS1 — legacy but still used) ---
SKIP: {
    $rsa->use_pkcs1_padding();
    $rsa->use_sha1_hash();
    my $sig = eval { $rsa->sign("sha1 test") };
    skip "SHA-1 signing not available on this system", 2 if $@;

    ok(defined $sig, "PKCS#1 v1.5 + SHA-1 sign produces signature");

    $rsa_pub->use_pkcs1_padding();
    $rsa_pub->use_sha1_hash();
    ok($rsa_pub->verify("sha1 test", $sig),
       "PKCS#1 v1.5 + SHA-1 signature verifies");
}

# --- Cross-padding: sign with PKCS1, verify with PSS must fail ---
# On pre-3.x and LibreSSL, RSA_verify ignores the padding mode setting
SKIP: {
    skip "cross-padding test requires OpenSSL 3.x (not LibreSSL)", 1
        if $major < 3 || $is_libressl;
    $rsa->use_pkcs1_padding();
    $rsa->use_sha256_hash();
    my $sig = $rsa->sign("cross-padding test");

    $rsa_pub->use_pkcs1_pss_padding();
    $rsa_pub->use_sha256_hash();
    my $result = eval { $rsa_pub->verify("cross-padding test", $sig) };
    ok(!$result, "PKCS1 signature does not verify with PSS padding");
}

# --- Encryption with PKCS1 must still croak (Marvin protection) ---
{
    $rsa->use_pkcs1_padding();
    eval { $rsa->encrypt("test") };
    like($@, qr/Marvin|vulnerable/i,
         "PKCS#1 v1.5 encryption still blocked (Marvin)");
}

# --- Reload key from PEM and verify signature ---
{
    $rsa->use_pkcs1_padding();
    $rsa->use_sha256_hash();
    my $sig = $rsa->sign("persistence test");

    my $priv_pem = $rsa->get_private_key_string();
    my $rsa2 = Crypt::OpenSSL::RSA->new_private_key($priv_pem);
    $rsa2->use_pkcs1_padding();
    $rsa2->use_sha256_hash();
    ok($rsa2->verify("persistence test", $sig),
       "signature verifies after key round-trip through PEM");

    my $rsa_pub2 = Crypt::OpenSSL::RSA->new_public_key($pub_pem);
    $rsa_pub2->use_pkcs1_padding();
    $rsa_pub2->use_sha256_hash();
    ok($rsa_pub2->verify("persistence test", $sig),
       "signature verifies with fresh public key object");
}
