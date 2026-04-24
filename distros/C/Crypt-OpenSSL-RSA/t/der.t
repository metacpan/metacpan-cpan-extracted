use strict;
use warnings;
use Test::More;
use MIME::Base64;
use Crypt::OpenSSL::RSA;

use File::Temp qw(tempfile);

BEGIN { plan tests => 30 }

# --- Generate a key pair for testing ---

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);

# --- Extract PEM public keys ---

my $pkcs1_pem = $rsa->get_public_key_string();        # PKCS#1 (BEGIN RSA PUBLIC KEY)
my $x509_pem  = $rsa->get_public_key_x509_string();   # X.509 (BEGIN PUBLIC KEY)

# --- Convert PEM to DER by stripping headers and base64-decoding ---

sub pem_to_der {
    my ($pem) = @_;
    $pem =~ s/-----BEGIN [^-]+-----//;
    $pem =~ s/-----END [^-]+-----//;
    $pem =~ s/\s+//g;
    return decode_base64($pem);
}

my $pkcs1_der = pem_to_der($pkcs1_pem);
my $x509_der  = pem_to_der($x509_pem);

# Sanity check: DER data starts with ASN.1 SEQUENCE tag
is( ord(substr($pkcs1_der, 0, 1)), 0x30, "PKCS#1 DER starts with SEQUENCE tag" );
is( ord(substr($x509_der, 0, 1)),  0x30, "X.509 DER starts with SEQUENCE tag" );

# --- Load DER keys via new_public_key ---

my ($pub_from_x509_der, $pub_from_pkcs1_der);

ok( $pub_from_x509_der = Crypt::OpenSSL::RSA->new_public_key($x509_der),
    "new_public_key loads X.509 DER key" );

ok( $pub_from_pkcs1_der = Crypt::OpenSSL::RSA->new_public_key($pkcs1_der),
    "new_public_key loads PKCS#1 DER key" );

# --- Verify round-trip: DER-loaded keys produce the same PEM output ---

is( $pub_from_x509_der->get_public_key_x509_string(), $x509_pem,
    "X.509 DER key exports to same X.509 PEM" );

is( $pub_from_x509_der->get_public_key_string(), $pkcs1_pem,
    "X.509 DER key exports to same PKCS#1 PEM" );

is( $pub_from_pkcs1_der->get_public_key_x509_string(), $x509_pem,
    "PKCS#1 DER key exports to same X.509 PEM" );

is( $pub_from_pkcs1_der->get_public_key_string(), $pkcs1_pem,
    "PKCS#1 DER key exports to same PKCS#1 PEM" );

# --- Verify DER-loaded keys can actually verify signatures ---

$rsa->use_sha256_hash();
my $plaintext = "Hello, DER world!";
my $sig = $rsa->sign($plaintext);

$pub_from_x509_der->use_sha256_hash();
ok( $pub_from_x509_der->verify($plaintext, $sig),
    "X.509 DER-loaded key verifies signature" );

$pub_from_pkcs1_der->use_sha256_hash();
ok( $pub_from_pkcs1_der->verify($plaintext, $sig),
    "PKCS#1 DER-loaded key verifies signature" );

# --- Private key DER support ---

my $priv_pem = $rsa->get_private_key_string();
my $priv_der = pem_to_der($priv_pem);

is( ord(substr($priv_der, 0, 1)), 0x30, "Private key DER starts with SEQUENCE tag" );

my $priv_from_der;
ok( $priv_from_der = Crypt::OpenSSL::RSA->new_private_key($priv_der),
    "new_private_key loads DER-encoded private key" );

ok( $priv_from_der->is_private(),
    "DER-loaded private key is recognized as private" );

is( $priv_from_der->get_public_key_x509_string(), $x509_pem,
    "DER-loaded private key exports same public key" );

# Verify DER-loaded private key can sign and original public key can verify
$priv_from_der->use_sha256_hash();
my $sig2 = $priv_from_der->sign($plaintext);
ok( $pub_from_x509_der->verify($plaintext, $sig2),
    "signature from DER-loaded private key verifies" );

# Error: DER-like data for private key
eval { Crypt::OpenSSL::RSA->new_private_key("\x30\x00") };
ok( $@, "new_private_key croaks on truncated DER data" );

# Error: bogus binary data for private key
eval { Crypt::OpenSSL::RSA->new_private_key("\x01\x02\x03\x04") };
like( $@, qr/unrecognized key format/,
    "new_private_key gives helpful error on random binary data" );

# PEM private keys still work through the wrapper
my $priv_from_pem;
ok( $priv_from_pem = Crypt::OpenSSL::RSA->new_private_key($priv_pem),
    "new_private_key still loads PEM-encoded private key" );

# --- Error cases ---

# DER-like data that isn't a valid key (no RSA OID, so falls through to PKCS#1 path)
eval { Crypt::OpenSSL::RSA->new_public_key("\x30\x00") };
ok( $@, "new_public_key croaks on truncated DER data" );

# Completely bogus binary data (not starting with 0x30)
eval { Crypt::OpenSSL::RSA->new_public_key("\x01\x02\x03\x04") };
like( $@, qr/unrecognized key format/,
    "new_public_key gives helpful error on random binary data" );

# Empty string
eval { Crypt::OpenSSL::RSA->new_public_key("") };
like( $@, qr/unrecognized key format/,
    "new_public_key gives helpful error on empty string" );

# --- Encrypted PKCS#8 DER private key with passphrase ---

my $passphrase = 'test_der_pass';
my $enc_pkcs8_pem = $rsa->get_private_key_pkcs8_string($passphrase, 'aes-128-cbc');
my $enc_pkcs8_der = pem_to_der($enc_pkcs8_pem);

is( ord(substr($enc_pkcs8_der, 0, 1)), 0x30,
    "Encrypted PKCS#8 DER starts with SEQUENCE tag" );

my $priv_from_enc_der;
ok( $priv_from_enc_der = Crypt::OpenSSL::RSA->new_private_key($enc_pkcs8_der, $passphrase),
    "new_private_key loads encrypted PKCS#8 DER with passphrase" );

ok( $priv_from_enc_der->is_private(),
    "Encrypted PKCS#8 DER-loaded key is private" );

is( $priv_from_enc_der->get_public_key_x509_string(), $x509_pem,
    "Encrypted PKCS#8 DER key exports same public key as original" );

$priv_from_enc_der->use_sha256_hash();
my $sig3 = $priv_from_enc_der->sign($plaintext);
ok( $pub_from_x509_der->verify($plaintext, $sig3),
    "Signature from encrypted PKCS#8 DER-loaded key verifies" );

eval { Crypt::OpenSSL::RSA->new_private_key($enc_pkcs8_der, 'wrong_pass') };
ok( $@, "new_private_key croaks on wrong passphrase for encrypted PKCS#8 DER" );

# PEM header for wrong type
eval { Crypt::OpenSSL::RSA->new_public_key("-----BEGIN CERTIFICATE-----\nfoo\n-----END CERTIFICATE-----\n") };
like( $@, qr/unrecognized key format/,
    "new_public_key gives helpful error on certificate PEM" );

# --- Non-RSA DER key rejection ---
# On OpenSSL 3.x, d2i_PUBKEY_bio() accepts any key type.
# _new_public_key_x509_der must reject non-RSA keys.

SKIP: {
    my $ec_pem = `openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 2>/dev/null`;
    skip "EC key generation not available", 2
        unless ($? >> 8) == 0 && $ec_pem =~ /-----BEGIN PRIVATE KEY-----/;

    my ($tmpfh, $tmpfile) = tempfile(UNLINK => 1);
    print $tmpfh $ec_pem;
    close $tmpfh;
    my $ec_pub_pem = `openssl pkey -in $tmpfile -pubout -outform PEM 2>/dev/null`;
    skip "EC public key export failed", 2
        unless ($? >> 8) == 0 && $ec_pub_pem =~ /-----BEGIN PUBLIC KEY-----/;

    my $ec_pub_der = pem_to_der($ec_pub_pem);
    eval { Crypt::OpenSSL::RSA->_new_public_key_x509_der($ec_pub_der) };
    ok($@, "_new_public_key_x509_der rejects EC DER key");
    like($@, qr/not an RSA key|ASN1|expecting an rsa key/i,
        "_new_public_key_x509_der gives appropriate error for non-RSA DER key");
}
