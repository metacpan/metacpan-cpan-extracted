use strict;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;

# Tests for private_encrypt() and public_decrypt() which use different
# OpenSSL code paths from encrypt()/decrypt():
#   pre-3.x: RSA_private_encrypt / RSA_public_decrypt
#   3.x:     EVP_PKEY_sign / EVP_PKEY_verify_recover

plan tests => 16;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $rsa  = Crypt::OpenSSL::RSA->generate_key(2048);
my $rsa2 = Crypt::OpenSSL::RSA->generate_key(2048);
my $key_size = $rsa->size();

my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($rsa->get_public_key_string());

# --- PKCS1 padding round-trip ---

{
    $rsa->use_pkcs1_padding();
    $rsa_pub->use_pkcs1_padding();

    my $plaintext = "private_encrypt with PKCS1 padding";
    my $ct = $rsa->private_encrypt($plaintext);
    ok(defined $ct && length($ct) > 0,
        "private_encrypt with PKCS1 padding produces output");

    my $pt = $rsa_pub->public_decrypt($ct);
    is($pt, $plaintext,
        "public_decrypt recovers plaintext with PKCS1 padding");
}

# --- No-padding round-trip ---

{
    $rsa->use_no_padding();
    $rsa_pub->use_no_padding();

    # no_padding requires exactly key_size bytes
    my $plaintext = "\x00" x ($key_size - 1) . "\x42";
    my $ct = $rsa->private_encrypt($plaintext);
    ok(defined $ct && length($ct) == $key_size,
        "private_encrypt with no padding produces key-sized output");

    my $pt = $rsa_pub->public_decrypt($ct);
    is($pt, $plaintext,
        "public_decrypt recovers plaintext with no padding");
}

# --- Binary data with embedded NUL bytes ---

{
    $rsa->use_pkcs1_padding();
    $rsa_pub->use_pkcs1_padding();

    # PKCS1 overhead is 11 bytes, so max plaintext = key_size - 11
    my $max_len = $key_size - 11;
    my $binary = "\x00\xFF\x00\x80\x00" . ("\xAB" x ($max_len - 6)) . "\x00";
    my $ct = $rsa->private_encrypt($binary);
    my $pt = $rsa_pub->public_decrypt($ct);
    is($pt, $binary,
        "binary data with embedded NULs round-trips through private_encrypt/public_decrypt");
}

# --- Max-length plaintext with PKCS1 ---

{
    $rsa->use_pkcs1_padding();
    $rsa_pub->use_pkcs1_padding();

    my $max_len = $key_size - 11;  # PKCS1 overhead
    my $plaintext = "X" x $max_len;
    my $ct = eval { $rsa->private_encrypt($plaintext) };
    ok(!$@, "private_encrypt at max PKCS1 plaintext length ($max_len bytes) succeeds")
        or diag $@;

    SKIP: {
        skip "private_encrypt failed", 1 if $@;
        is($rsa_pub->public_decrypt($ct), $plaintext,
            "max-length PKCS1 plaintext round-trips correctly");
    }
}

# --- Plaintext too long for PKCS1 ---

{
    $rsa->use_pkcs1_padding();
    my $too_long = "X" x ($key_size - 10);
    eval { $rsa->private_encrypt($too_long) };
    ok($@, "private_encrypt with plaintext too long for PKCS1 croaks");
}

# --- Cross-key: private_encrypt with key1, public_decrypt with key2 ---

{
    $rsa->use_pkcs1_padding();
    $rsa2->use_pkcs1_padding();

    my $ct = $rsa->private_encrypt("cross key test");
    eval { $rsa2->public_decrypt($ct) };
    ok($@, "public_decrypt with wrong key croaks");
}

# --- public_decrypt of garbage data ---

{
    $rsa_pub->use_pkcs1_padding();

    eval { $rsa_pub->public_decrypt("G" x $key_size) };
    ok($@, "public_decrypt of garbage data croaks");
}

# --- public_decrypt of truncated ciphertext ---

{
    $rsa->use_pkcs1_padding();
    $rsa_pub->use_pkcs1_padding();

    my $ct = $rsa->private_encrypt("truncation test");
    my $truncated = substr($ct, 0, length($ct) - 10);
    eval { $rsa_pub->public_decrypt($truncated) };
    ok($@, "public_decrypt of truncated ciphertext croaks");
}

# --- PSS padding rejected for private_encrypt ---

{
    $rsa->use_pkcs1_pss_padding();
    eval { $rsa->private_encrypt("pss test") };
    ok($@, "PSS padding cannot be used with private_encrypt");
}

# --- OAEP padding rejected for private_encrypt ---
# OAEP is an encryption scheme, invalid for sign-type operations.

{
    $rsa->use_pkcs1_oaep_padding();
    eval { $rsa->private_encrypt("oaep test") };
    ok($@, "OAEP padding cannot be used with private_encrypt");
}

# --- Public key cannot private_encrypt ---

{
    $rsa_pub->use_pkcs1_padding();
    eval { $rsa_pub->private_encrypt("should fail") };
    like($@, qr/Public keys cannot private_encrypt/,
        "public key cannot call private_encrypt");
}

# --- Verify interop: private_encrypt produces data that sign() does not ---
# private_encrypt operates on raw data; sign() hashes first.  The outputs
# for the same input should differ.

{
    $rsa->use_pkcs1_padding();
    my $msg = "interop test message";
    my $ct = $rsa->private_encrypt($msg);

    $rsa->use_sha256_hash();
    $rsa->use_pkcs1_padding();
    my $sig = $rsa->sign($msg);

    isnt($ct, $sig,
        "private_encrypt and sign produce different outputs for same message");
}

# --- Empty string with PKCS1 padding ---
# Note: empty-string round-trip behavior varies across OpenSSL versions.
# On 3.x, EVP_PKEY_verify_recover of a zero-length payload may return
# a "provider signature failure" error.  We only test that private_encrypt
# succeeds; public_decrypt may legitimately fail on some versions.

{
    $rsa->use_pkcs1_padding();
    $rsa_pub->use_pkcs1_padding();

    my $ct = eval { $rsa->private_encrypt("") };
    ok(!$@, "private_encrypt of empty string with PKCS1 succeeds")
        or diag $@;
}
