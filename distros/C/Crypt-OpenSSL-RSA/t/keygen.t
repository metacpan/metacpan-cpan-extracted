use strict;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;

# Tests for generate_key() with non-default exponents and edge cases.
# The default exponent (65537) is well-tested elsewhere; this file
# exercises the explicit exponent parameter and verifies generated keys
# are fully functional.

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $HAS_BIGNUM = eval { require Crypt::OpenSSL::Bignum; 1 } ? 1 : 0;

# Use 2048-bit keys throughout — AlmaLinux 9 and other FIPS-like systems
# enforce a minimum RSA key size of 2048 bits.
my $BITS = 2048;
my $BYTES = $BITS / 8;

plan tests => 29;

# --- Default exponent (65537) explicitly passed ---
{
    my $rsa = Crypt::OpenSSL::RSA->generate_key($BITS, 65537);
    ok($rsa, "generate_key with explicit default exponent 65537");
    is($rsa->size(), $BYTES, "key size is $BYTES bytes ($BITS bits)");
    ok($rsa->is_private(), "generated key is private");
    ok($rsa->check_key(), "key passes check_key");

    SKIP: {
        skip "Crypt::OpenSSL::Bignum not available", 1 unless $HAS_BIGNUM;
        my (undef, $e) = $rsa->get_key_parameters();
        is($e->to_decimal(), "65537", "exponent is 65537");
    }
}

# --- Small valid exponent: 3 ---
{
    my $rsa = eval { Crypt::OpenSSL::RSA->generate_key($BITS, 3) };
    SKIP: {
        skip "OpenSSL rejected exponent 3: $@", 5 if $@;
        ok($rsa, "generate_key with exponent 3");
        ok($rsa->check_key(), "e=3 key passes check_key");

        # Verify e=3 key can sign/verify
        $rsa->use_sha256_hash();
        $rsa->use_pkcs1_pss_padding();
        my $sig = $rsa->sign("test message");
        ok($sig, "e=3 key can sign");
        ok($rsa->verify("test message", $sig), "e=3 key signature verifies");

        SKIP: {
            skip "Crypt::OpenSSL::Bignum not available", 1 unless $HAS_BIGNUM;
            my (undef, $e) = $rsa->get_key_parameters();
            is($e->to_decimal(), "3", "exponent is 3");
        }
    }
}

# --- Valid exponent: 17 ---
{
    my $rsa = eval { Crypt::OpenSSL::RSA->generate_key($BITS, 17) };
    SKIP: {
        skip "OpenSSL rejected exponent 17: $@", 4 if $@;
        ok($rsa, "generate_key with exponent 17");
        ok($rsa->check_key(), "e=17 key passes check_key");

        # Verify encrypt/decrypt works
        $rsa->use_pkcs1_oaep_padding();
        my $ct = $rsa->encrypt("hello");
        my $pt = $rsa->decrypt($ct);
        is($pt, "hello", "e=17 key encrypt/decrypt round-trip");

        SKIP: {
            skip "Crypt::OpenSSL::Bignum not available", 1 unless $HAS_BIGNUM;
            my (undef, $e) = $rsa->get_key_parameters();
            is($e->to_decimal(), "17", "exponent is 17");
        }
    }
}

# --- Valid exponent: 257 ---
{
    my $rsa = eval { Crypt::OpenSSL::RSA->generate_key($BITS, 257) };
    SKIP: {
        skip "OpenSSL rejected exponent 257: $@", 2 if $@;
        ok($rsa, "generate_key with exponent 257");
        ok($rsa->check_key(), "e=257 key passes check_key");
    }
}

# --- Invalid exponent: even number (2) ---
# OpenSSL 1.1.x may loop forever on invalid exponents instead of
# rejecting them, so we use alarm() to avoid hanging CI.
{
    my $rsa = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(10);
        my $r = Crypt::OpenSSL::RSA->generate_key($BITS, 2);
        alarm(0);
        $r;
    };
    alarm(0);
    ok(!$rsa || $@, "exponent 2 (even) is rejected or times out");
}

# --- Invalid exponent: 1 ---
{
    my $rsa = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(10);
        my $r = Crypt::OpenSSL::RSA->generate_key($BITS, 1);
        alarm(0);
        $r;
    };
    alarm(0);
    ok(!$rsa || $@, "exponent 1 is rejected or times out");
}

# --- Key reuse after error ---
# Generate a key, trigger an eval-caught error, then use the key again.
# Validates the key object isn't corrupted by a caught failure.
{
    my $rsa = Crypt::OpenSSL::RSA->generate_key($BITS);
    $rsa->use_pkcs1_oaep_padding();

    # Trigger an error: plaintext too long for OAEP
    my $too_long = "x" x ($rsa->size());
    eval { $rsa->encrypt($too_long) };
    ok($@, "encrypt with oversized plaintext fails as expected");

    # Key should still work for a valid operation
    my $ct = eval { $rsa->encrypt("works after error") };
    ok(!$@, "key is reusable after caught encrypt error") or diag $@;
    my $pt = eval { $rsa->decrypt($ct) };
    is($pt, "works after error", "decrypt succeeds after prior error");
}

# --- Hash mode switching ---
# Verify that changing hash modes on a key object works correctly.
{
    my $rsa = Crypt::OpenSSL::RSA->generate_key($BITS);
    $rsa->use_pkcs1_pss_padding();
    my $msg = "hash switching test";

    $rsa->use_sha256_hash();
    my $sig256 = $rsa->sign($msg);
    ok($rsa->verify($msg, $sig256), "SHA256 sign/verify after mode set");

    # SHA1 signing may be disabled on FIPS-like systems (e.g. almalinux:9)
    SKIP: {
        $rsa->use_sha1_hash();
        my $sig1 = eval { $rsa->sign($msg) };
        skip "SHA1 signing not available: $@", 2 if $@;
        ok($rsa->verify($msg, $sig1), "SHA1 sign/verify after switching from SHA256");

        # SHA256 signature should NOT verify under SHA1
        my $result = eval { $rsa->verify($msg, $sig256) };
        ok(!$result, "SHA256 signature fails under SHA1 mode");
    }
}

# --- Key size validation ---
{
    eval { Crypt::OpenSSL::RSA->generate_key(-1) };
    like($@, qr/at least 512 bits/, "generate_key croaks on negative key size");

    eval { Crypt::OpenSSL::RSA->generate_key(0) };
    like($@, qr/at least 512 bits/, "generate_key croaks on zero key size");

    eval { Crypt::OpenSSL::RSA->generate_key(256) };
    like($@, qr/at least 512 bits/, "generate_key croaks on 256-bit key size");

    eval { Crypt::OpenSSL::RSA->generate_key(511) };
    like($@, qr/at least 512 bits/, "generate_key croaks on 511-bit key size");

    my $rsa = eval { Crypt::OpenSSL::RSA->generate_key(512) };
    ok($rsa && !$@, "generate_key accepts 512-bit key size (minimum)");
}
