use strict;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);
my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($rsa->get_public_key_string());

# --- Malformed key loading ---

eval { Crypt::OpenSSL::RSA->new_private_key("not a key at all") };
ok($@, "new_private_key croaks on garbage input");

eval { Crypt::OpenSSL::RSA->new_private_key("") };
ok($@, "new_private_key croaks on empty string");

eval { Crypt::OpenSSL::RSA->new_private_key(undef) };
ok($@, "new_private_key croaks on undef");

eval {
    Crypt::OpenSSL::RSA->new_private_key(
        "-----BEGIN RSA PRIVATE KEY-----\ngarbage\n-----END RSA PRIVATE KEY-----\n"
    );
};
ok($@, "new_private_key croaks on corrupted PEM body");

eval { Crypt::OpenSSL::RSA->_new_public_key_pkcs1("not a key") };
ok($@, "_new_public_key_pkcs1 croaks on garbage input");

eval { Crypt::OpenSSL::RSA->_new_public_key_x509("not a key") };
ok($@, "_new_public_key_x509 croaks on garbage input");

# --- Unrecognized public key format (Perl-level croak) ---

eval { Crypt::OpenSSL::RSA->new_public_key("-----BEGIN CERTIFICATE-----\nfoo\n-----END CERTIFICATE-----\n") };
like($@, qr/unrecognized key format/, "new_public_key croaks on unrecognized PEM header");

eval { Crypt::OpenSSL::RSA->new_public_key("just plain text") };
like($@, qr/unrecognized key format/, "new_public_key croaks on plain text");

# --- Wrong passphrase on encrypted key ---

my $encrypted_pem = $rsa->get_private_key_string("correct_passphrase", "aes-128-cbc");
eval { Crypt::OpenSSL::RSA->new_private_key($encrypted_pem, "wrong_passphrase") };
ok($@, "new_private_key croaks on wrong passphrase");

# Note: testing with no passphrase or empty passphrase is intentionally
# omitted — OpenSSL may prompt on the terminal, hanging non-interactive runs.

# --- Public key cannot perform private operations ---

eval { $rsa_pub->sign("hello") };
like($@, qr/Public keys cannot sign/i, "public key cannot sign");

eval { $rsa_pub->decrypt("hello") };
like($@, qr/Public keys cannot decrypt/i, "public key cannot decrypt");

eval { $rsa_pub->private_encrypt("hello") };
like($@, qr/Public keys cannot private_encrypt/i, "public key cannot private_encrypt");

eval { $rsa_pub->check_key() };
like($@, qr/Public keys cannot be checked/i, "public key cannot check_key");

# --- Corrupted ciphertext ---

$rsa->use_pkcs1_oaep_padding();
my $ciphertext = $rsa->encrypt("test message");

# Flip bits in ciphertext
my $corrupted = $ciphertext;
substr($corrupted, 10, 1) ^= "\xff";
eval { $rsa->decrypt($corrupted) };
ok($@, "decrypt croaks on corrupted ciphertext");

# Wrong-length ciphertext
eval { $rsa->decrypt("too short") };
ok($@, "decrypt croaks on wrong-length ciphertext");

eval { $rsa->decrypt("") };
ok($@, "decrypt croaks on empty ciphertext");

# --- Plaintext too large for padding mode ---

$rsa->use_pkcs1_oaep_padding();
my $max_oaep = $rsa->size() - 42;
my $too_large = "x" x ($max_oaep + 1);
eval { $rsa->encrypt($too_large) };
ok($@, "encrypt croaks when plaintext exceeds OAEP max size");

# Exact max should work
my $exact_max = "x" x $max_oaep;
my $ct = eval { $rsa->encrypt($exact_max) };
ok(!$@, "encrypt succeeds at exact OAEP max size");
is(eval { $rsa->decrypt($ct) }, $exact_max, "round-trip at OAEP max size");

# --- Cross-key signature verification ---

my $rsa2 = Crypt::OpenSSL::RSA->generate_key(2048);
$rsa->use_pkcs1_pss_padding();
$rsa2->use_pkcs1_pss_padding();

my $sig = $rsa->sign("message to sign");
ok(!eval { $rsa2->verify("message to sign", $sig) }, "signature from key1 does not verify with key2");

my $rsa2_pub = Crypt::OpenSSL::RSA->new_public_key($rsa2->get_public_key_string());
$rsa2_pub->use_pkcs1_pss_padding();
ok(!eval { $rsa2_pub->verify("message to sign", $sig) }, "signature from key1 does not verify with key2 public");

# --- Empty message signing ---

my $empty_sig = eval { $rsa->sign("") };
ok(!$@, "sign succeeds on empty message");
ok($rsa->verify("", $empty_sig), "verify succeeds on empty message signature");
ok(!$rsa->verify("not empty", $empty_sig), "empty message signature does not verify different message");

# --- Truncated signature ---

my $full_sig = $rsa->sign("test data");
my $truncated_sig = substr($full_sig, 0, length($full_sig) - 1);
ok(!eval { $rsa->verify("test data", $truncated_sig) }, "truncated signature does not verify");

my $extended_sig = $full_sig . "\x00";
ok(!eval { $rsa->verify("test data", $extended_sig) }, "extended signature does not verify");

# --- Key size boundary ---

my $small_rsa = eval { Crypt::OpenSSL::RSA->generate_key(512) };
SKIP: {
    skip "OpenSSL 3.x rejects 512-bit keys at default security level", 2 if $@;
    ok($small_rsa, "512-bit key generation succeeds");
    is($small_rsa->size() * 8, 512, "512-bit key has correct size");
}

# --- generate_key with custom exponent ---

my $rsa_e3 = eval { Crypt::OpenSSL::RSA->generate_key(2048, 3) };
SKIP: {
    skip "OpenSSL rejected exponent 3", 2 if $@;
    ok($rsa_e3, "generate_key with exponent 3 succeeds");
    ok($rsa_e3->check_key(), "key with exponent 3 passes check_key");
}

my $rsa_e17 = eval { Crypt::OpenSSL::RSA->generate_key(2048, 17) };
SKIP: {
    skip "OpenSSL rejected exponent 17", 2 if $@;
    ok($rsa_e17, "generate_key with exponent 17 succeeds");
    ok($rsa_e17->check_key(), "key with exponent 17 passes check_key");
}

# Even exponent should fail
eval { Crypt::OpenSSL::RSA->generate_key(2048, 2) };
ok($@, "generate_key croaks on even exponent");

done_testing;
