use strict;
use warnings;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
plan tests => 14;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);
my $key_size = $rsa->size();

# --- NO_PADDING: private_encrypt / public_decrypt roundtrip ---

$rsa->use_no_padding();
my $data = "\0" x ($key_size - 11) . "Hello World";
my $enc = $rsa->private_encrypt($data);
ok(defined $enc, "private_encrypt with no_padding succeeds");
my $dec = $rsa->public_decrypt($enc);
is($dec, $data, "public_decrypt(private_encrypt(data)) round-trips with no_padding");

# --- OAEP: should croak for private_encrypt ---

$rsa->use_pkcs1_oaep_padding();
eval { $rsa->private_encrypt("test") };
like($@, qr/OAEP padding is not supported for private_encrypt/,
     "private_encrypt with OAEP croaks with clear message");

# --- OAEP: should croak for public_decrypt ---

eval { $rsa->public_decrypt("test" x 64) };
like($@, qr/OAEP padding is not supported for private_encrypt\/public_decrypt/,
     "public_decrypt with OAEP croaks with clear message");

# --- PSS: should croak for private_encrypt ---

$rsa->use_pkcs1_pss_padding();
eval { $rsa->private_encrypt("test") };
like($@, qr/PSS padding with private_encrypt\/public_decrypt is not supported/,
     "private_encrypt with PSS croaks with clear message");

# --- PSS: should croak for public_decrypt ---

eval { $rsa->public_decrypt("test" x 64) };
like($@, qr/PSS padding with private_encrypt\/public_decrypt is not supported/,
     "public_decrypt with PSS croaks with clear message");

# --- Error ordering: padding error must come before length error ---

{
    my $rsa_fresh = Crypt::OpenSSL::RSA->generate_key(2048);
    my $large_data = "x" x 250;  # exceeds OAEP limit (256 - 42 = 214)
    eval { $rsa_fresh->private_encrypt($large_data) };
    like($@, qr/OAEP padding is not supported for private_encrypt/,
         "private_encrypt with default OAEP + oversized data gives padding error, not length error");

    $rsa_fresh->use_pkcs1_pss_padding();
    eval { $rsa_fresh->private_encrypt($large_data) };
    like($@, qr/PSS padding with private_encrypt\/public_decrypt is not supported/,
         "private_encrypt with PSS + oversized data gives padding error, not length error");

    $rsa_fresh->use_pkcs1_oaep_padding();
    my $exact_data = "y" x 215;  # just over OAEP limit
    eval { $rsa_fresh->private_encrypt($exact_data) };
    like($@, qr/OAEP padding is not supported for private_encrypt/,
         "private_encrypt with OAEP + barely-over-limit data gives padding error, not length error");

    $rsa_fresh->use_pkcs1_padding();
    eval { $rsa_fresh->private_encrypt("test") };
    ok(!$@, "private_encrypt with PKCS#1 v1.5 padding works");
}

# --- Encryption operations still work correctly ---

$rsa->use_pkcs1_oaep_padding();
my $plaintext = "Hello World";
my $ciphertext = $rsa->encrypt($plaintext);
ok(defined $ciphertext, "encrypt with OAEP still works");
is($rsa->decrypt($ciphertext), $plaintext, "decrypt with OAEP round-trips");

# --- PSS still croaks for encrypt ---

$rsa->use_pkcs1_pss_padding();
eval { $rsa->encrypt($plaintext) };
like($@, qr/RSA-PSS cannot be used for encryption/,
     "encrypt with PSS still croaks");

# --- Public key cannot private_encrypt ---

my $pub_key_string = $rsa->get_public_key_string();
my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($pub_key_string);
$rsa_pub->use_no_padding();
eval { $rsa_pub->private_encrypt("\0" x $key_size) };
like($@, qr/Public keys cannot private_encrypt/,
     "public key private_encrypt croaks");
