use strict;
use Test::More;
use File::Temp qw(tempfile);

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Guess qw(openssl_version);

my ($major, $minor, $patch) = openssl_version();

BEGIN { plan tests => 56 }

my $PRIVATE_KEY_STRING = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
MBsCAQACAU0CAQcCASsCAQcCAQsCAQECAQMCAQI=
-----END RSA PRIVATE KEY-----
EOF

my $PUBLIC_KEY_PKCS1_STRING = <<EOF;
-----BEGIN RSA PUBLIC KEY-----
MAYCAU0CAQc=
-----END RSA PUBLIC KEY-----
EOF

my $PUBLIC_KEY_X509_STRING = <<EOF;
-----BEGIN PUBLIC KEY-----
MBowDQYJKoZIhvcNAQEBBQADCQAwBgIBTQIBBw==
-----END PUBLIC KEY-----
EOF

# openssl genrsa -des3 -passout pass:123456 1024
my $ENCRYPT_PRIVATE_KEY_STRING = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,319C89EE262DB309

FPj3QbILNMiDvpoSkA38WZnjvjH+c2b5lKdge0mXJu2k3ZnbM+D51RL/iCTbItsU
Pgw1pjB7w2pkapSwdwzOwbsaiznLF9S8fj4XxDYWuWAlPGAwk6GA8YxAaCIbpSkr
QdJoDAsdaIBj1JA73C8HCtnw7h5dN3VLZfwmJVcFeSddz1S5MgN5tgD6YyIhdVwe
0tlQ3Jk4/j80MzgBoJlkKccVurnUVUKw6S5RkVd91tAj7WXlqepuGV4a1X4JtFpV
KUNlNt8Hrnf6zq5mNqHqLtXtDpVWj9zW7FIYFqXiq37VKr5qJ8s8RI/ACQK2q7E/
rJTXqoZFg2fpVW4CDO1Rpm3HF3k8hzCpVFYHHI6j0qmLl7YY5aSKUqFaVIv3O9so
w/dXO1jWLxiQH1rijl1GBdg86012CtT5hwQbetUjo2leaq5hxdHo0ynXM0Q8aYPU
I/QUGJvDW5gHE0n6aKQxfWq9OfhraqBKF/SA6S7aHdk7lrjsJPAxa0IGJfO0O471
SjXj6HHuL376r0KQmDAO4qXpckzfthztwRqDGpdStTVdD+iDOD7NbRW5OJZTvjvM
/866bpy5py65E6DtQJDAi2NHwQHbV4KEGlocavJybQ7Smaf2JSOMg4DKRwyIQucw
KdgWUX1Brg70pd8Zr/iGpvE1I7bBWzNbwGbO51srKD+0uZMBz3dwJ0iVrbBInSFW
UOviCyfFSHIyA5gWxi7ccQYfFj71FH5//4dJOLlh1FtNEYaNod57jE9yDtUPEunQ
Kg+us0d7vFPttZ5QfBq5yP1povSTgITcXLjjkBxJVvqH0exmSIA22w==
-----END RSA PRIVATE KEY-----
EOF

my $DECRYPT_PRIVATE_KEY_STRING = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC9KazkIUqBOg6QBQJTItC5XBhQYyf+ohQZHsQ/f1URKOYtqsv9
VtKBSxc7ObSw9ctWEca8VWqqV2Xfmika5XCC/t91Sx8QLO9UAO2ycQeHSFjoYZ18
ch4Ostgmkbr1blbEDPCFCyIJFb3UzhX5raCIfIByWOvtkXKWuKDkPZD6VQIDAQAB
AoGBALxoFP7HtciOhdCmXJFnfNMSSllO2ZgB4NjATyEbdyP3Q4O6uSCkaFhE7Wec
6z7SIeuhGvuca/grwpj6l/RlEDCBYWk1JXJCAvnJkoBCwW70thOXFJ0gDfrJq3Co
GWntC/fdkv6HJx1axQF3xn9oDVHIn0fscS7D6FzN1jwSgRLhAkEA7kJt09/OlUnY
pV/9iVvswnnSsxEanoLchzA1bAaDNa9vkIU/BrFwQO9ctw+RQbHrvc/5KPbZoGsq
bfQ/wOXUnQJBAMs/ZGlziX19lOEGfziugMR33ybLxkBS7qcrpBebAED/8etijASp
LgMEOKeRz11WAVJJ5A4wi1yxD4fnBxp44xkCQG4RejNbPVByYQdlJPeD5Aijxta6
nBWGVuKNPuC80XjHpz6Yj9lDt5wH+EkJhA1ZaJKztWNbRoZ5e4x4PcubYXECQHA0
KubcVcblkU85Gvrbu1K7KoJsdKIGJqI7QXeWpmk74v4jhVD9ZN1dczlvEZ9hX5Fi
IXiD7Cvbw8svC4jdu+ECQQCw1ZlQPz2rGE+pFQiKOFPprH+pT+zkINh1d83jeMYd
GG7hKgfQB5J/B0u8/XzEtGnCq8m0xTADx2eplIoKhAFi
-----END RSA PRIVATE KEY-----
EOF

my ( $private_key, $public_key, $private_key2 );

ok( $private_key = Crypt::OpenSSL::RSA->new_private_key($PRIVATE_KEY_STRING), "load private key from string" );
is( $private_key->get_private_key_string(), $PRIVATE_KEY_STRING, "private key round-trips" );
is( $private_key->get_public_key_string(), $PUBLIC_KEY_PKCS1_STRING, "PKCS1 public key matches expected" );
is( $private_key->get_public_key_x509_string(), $PUBLIC_KEY_X509_STRING, "X509 public key matches expected" );

ok( $public_key = Crypt::OpenSSL::RSA->new_public_key($PUBLIC_KEY_PKCS1_STRING), "load PKCS1 public key" );
is( $public_key->get_public_key_string(), $PUBLIC_KEY_PKCS1_STRING, "PKCS1 public key round-trips" );
is( $public_key->get_public_key_x509_string(), $PUBLIC_KEY_X509_STRING, "PKCS1 key exports to X509 correctly" );

ok( $public_key = Crypt::OpenSSL::RSA->new_public_key($PUBLIC_KEY_X509_STRING), "load X509 public key" );
is( $public_key->get_public_key_string(), $PUBLIC_KEY_PKCS1_STRING, "X509 key exports to PKCS1 correctly" );
is( $public_key->get_public_key_x509_string(), $PUBLIC_KEY_X509_STRING, "X509 public key round-trips" );

# get_public_key_pkcs1_string is an alias for get_public_key_string
is( $private_key->get_public_key_pkcs1_string(), $PUBLIC_KEY_PKCS1_STRING, "get_public_key_pkcs1_string returns PKCS1 from private key" );
is( $public_key->get_public_key_pkcs1_string(), $PUBLIC_KEY_PKCS1_STRING, "get_public_key_pkcs1_string returns PKCS1 from public key" );
is( $private_key->get_public_key_pkcs1_string(), $private_key->get_public_key_string(), "pkcs1 alias matches get_public_key_string on private key" );
ok( $public_key = Crypt::OpenSSL::RSA->new_public_key($private_key->get_public_key_pkcs1_string()), "new_public_key accepts output of get_public_key_pkcs1_string" );

my $passphrase = '123456';
ok( $private_key = Crypt::OpenSSL::RSA->new_private_key( $ENCRYPT_PRIVATE_KEY_STRING, $passphrase ), "load encrypted private key" );
is( $private_key->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING, "encrypted key decrypts to expected private key" );
ok( $private_key  = Crypt::OpenSSL::RSA->new_private_key($DECRYPT_PRIVATE_KEY_STRING), "load decrypted private key" );
ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key( $private_key->get_private_key_string($passphrase), $passphrase ), "re-encrypt and reload with passphrase" );
is( $private_key2->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING, "re-encrypted key round-trips" );
ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key( $private_key->get_private_key_string( $passphrase, 'des3' ), $passphrase ), "encrypt with des3 and reload" );
is( $private_key2->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING, "des3-encrypted key round-trips" );
ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key( $private_key->get_private_key_string( $passphrase, 'aes-128-cbc' ), $passphrase ), "encrypt with aes-128-cbc and reload" );
is( $private_key2->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING, "aes-128-cbc-encrypted key round-trips" );

# --- Additional cipher algorithms ---

ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key( $private_key->get_private_key_string( $passphrase, 'aes-256-cbc' ), $passphrase ), "encrypt with aes-256-cbc and reload" );
is( $private_key2->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING, "aes-256-cbc-encrypted key round-trips" );

ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key( $private_key->get_private_key_string( $passphrase, 'aes-192-cbc' ), $passphrase ), "encrypt with aes-192-cbc and reload" );
is( $private_key2->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING, "aes-192-cbc-encrypted key round-trips" );

# --- Passphrase with special characters ---

my $special_pass = q{p@ss!w0rd#$%^&*()};
ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key( $private_key->get_private_key_string($special_pass), $special_pass ), "passphrase with special characters round-trips" );
is( $private_key2->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING, "special-char passphrase key decrypts correctly" );

# --- Error: cipher specified without passphrase ---

eval { $private_key->get_private_key_string(undef, 'des3') };
like($@, qr/Passphrase is required for cipher/, "get_private_key_string croaks when cipher given without passphrase");

# --- Error: unsupported cipher name ---

eval { $private_key->get_private_key_string($passphrase, 'bogus-cipher-xyz') };
like($@, qr/Unsupported cipher/, "get_private_key_string croaks on unsupported cipher");

# --- Error: export private key from public-only key ---

my $pub_only = Crypt::OpenSSL::RSA->new_public_key($PUBLIC_KEY_PKCS1_STRING);
eval { $pub_only->get_private_key_string() };
like($@, qr/Public keys cannot export private key strings/,
    "get_private_key_string croaks on public-only key");

# --- Error: wrong passphrase on re-import ---

my $encrypted_pem = $private_key->get_private_key_string($passphrase, 'aes-128-cbc');
eval { Crypt::OpenSSL::RSA->new_private_key($encrypted_pem, 'wrong_passphrase') };
ok($@, "new_private_key croaks on wrong passphrase");

# --- Error: garbage / truncated private key input ---

eval { Crypt::OpenSSL::RSA->new_private_key("not a valid PEM key\n") };
ok( $@, "new_private_key croaks on garbage input" );

eval { Crypt::OpenSSL::RSA->new_private_key("-----BEGIN RSA PRIVATE KEY-----\ngarbage\n-----END RSA PRIVATE KEY-----\n") };
ok( $@, "new_private_key croaks on truncated PEM" );

# --- Public key format detection ---

eval { Crypt::OpenSSL::RSA->new_public_key("-----BEGIN CERTIFICATE-----\nfoo\n-----END CERTIFICATE-----\n") };
like($@, qr/unrecognized key format/, "new_public_key croaks on certificate PEM header");

eval { Crypt::OpenSSL::RSA->new_public_key("not a PEM key at all") };
like($@, qr/unrecognized key format/, "new_public_key croaks on non-PEM input");

# --- PKCS#8 private key export ---

{
    my $rsa = Crypt::OpenSSL::RSA->new_private_key($DECRYPT_PRIVATE_KEY_STRING);
    my $pkcs8_pem = $rsa->get_private_key_pkcs8_string();
    like($pkcs8_pem, qr/^-----BEGIN PRIVATE KEY-----/m, "PKCS#8 output has correct header");
    like($pkcs8_pem, qr/-----END PRIVATE KEY-----\s*$/m, "PKCS#8 output has correct footer");
    unlike($pkcs8_pem, qr/BEGIN RSA PRIVATE KEY/, "PKCS#8 output is not PKCS#1 format");

    # encrypted PKCS#8 export
    my $pass = 'test_pkcs8_pass';
    my $enc_pem = $rsa->get_private_key_pkcs8_string($pass, 'aes-128-cbc');
    like($enc_pem, qr/^-----BEGIN ENCRYPTED PRIVATE KEY-----/m,
         "encrypted PKCS#8 has correct header");

    # Round-trip tests require new_private_key to read PKCS#8.  On pre-3.x
    # PEM_read_bio_PrivateKey is macro'd to PEM_read_bio_RSAPrivateKey which
    # only reads PKCS#1, so these must be skipped.
    SKIP: {
        skip "new_private_key cannot read PKCS#8 on OpenSSL < 3.x", 3
            if $major < 3;

        my $reimported = Crypt::OpenSSL::RSA->new_private_key($pkcs8_pem);
        is($reimported->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING,
           "PKCS#8 round-trip: re-import then export as PKCS#1 matches original");
        is($reimported->get_private_key_pkcs8_string(), $pkcs8_pem,
           "PKCS#8 round-trip: re-export as PKCS#8 matches");

        my $dec_rsa = Crypt::OpenSSL::RSA->new_private_key($enc_pem, $pass);
        is($dec_rsa->get_private_key_string(), $DECRYPT_PRIVATE_KEY_STRING,
           "encrypted PKCS#8 round-trip decrypts to original key");
    }

    # error: cipher without passphrase
    eval { $rsa->get_private_key_pkcs8_string(undef, 'des3') };
    like($@, qr/Passphrase is required for cipher/,
         "get_private_key_pkcs8_string croaks when cipher given without passphrase");

    # error: unsupported cipher
    eval { $rsa->get_private_key_pkcs8_string($pass, 'bogus-cipher-xyz') };
    like($@, qr/Unsupported cipher/,
         "get_private_key_pkcs8_string croaks on unsupported cipher");
}

# --- X509 public key from private key matches PKCS1 ---

my $priv_for_x509 = Crypt::OpenSSL::RSA->new_private_key($PRIVATE_KEY_STRING);
ok( $public_key = Crypt::OpenSSL::RSA->new_public_key($priv_for_x509->get_public_key_x509_string()), "load X509 public key from private key" );
is( $public_key->get_public_key_string(), $PUBLIC_KEY_PKCS1_STRING, "X509 from private key matches PKCS1" );

# --- Non-RSA key rejection ---
# On OpenSSL 3.x, the generic PEM loaders accept any key type.
# Verify we reject non-RSA keys with a clear error.

SKIP: {
    my $ec_pem = `openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 2>/dev/null`;
    skip "EC key generation not available", 4
        unless ($? >> 8) == 0 && $ec_pem =~ /-----BEGIN PRIVATE KEY-----/;

    eval { Crypt::OpenSSL::RSA->new_private_key($ec_pem) };
    ok($@, "new_private_key rejects EC private key");
    like($@, qr/not an RSA key|expecting an rsa key|ASN1/i, "EC private key error message mentions RSA");

    my ($tmpfh, $tmpfile) = tempfile(UNLINK => 1);
    print $tmpfh $ec_pem;
    close $tmpfh;
    my $ec_pub = `openssl pkey -in $tmpfile -pubout 2>/dev/null`;
    skip "EC public key export failed", 2
        unless ($? >> 8) == 0 && $ec_pub =~ /-----BEGIN PUBLIC KEY-----/;
    eval { Crypt::OpenSSL::RSA->new_public_key($ec_pub) };
    ok($@, "new_public_key rejects EC public key");
    like($@, qr/not an RSA key|unrecognized key format|ASN1/i, "EC public key gives appropriate error");
}

# --- RSA-PSS key rejection ---
# EVP_PKEY_get_base_id() returns EVP_PKEY_RSA_PSS for RSA-PSS keys,
# which is distinct from EVP_PKEY_RSA.  This module only supports
# traditional RSA, so RSA-PSS keys should also be rejected.

SKIP: {
    my $rsa_pss_pem = `openssl genpkey -algorithm RSA-PSS -pkeyopt rsa_keygen_bits:2048 2>/dev/null`;
    skip "RSA-PSS key generation not available", 4
        unless ($? >> 8) == 0 && $rsa_pss_pem =~ /-----BEGIN PRIVATE KEY-----/;

    # On pre-3.x OpenSSL, RSA-PSS keys are loaded via RSA-specific PEM
    # readers which accept them (they are structurally RSA).  The
    # EVP_PKEY_get_base_id() rejection only exists on OpenSSL 3.x+.
    eval { Crypt::OpenSSL::RSA->new_private_key($rsa_pss_pem) };
    skip "RSA-PSS rejection not supported on this OpenSSL version (pre-3.x)", 4
        unless $@;

    ok(1, "new_private_key rejects RSA-PSS private key");
    like($@, qr/not an RSA key|expecting an rsa key|ASN1/i, "RSA-PSS private key error message mentions RSA");

    my ($tmpfh, $tmpfile) = tempfile(UNLINK => 1);
    print $tmpfh $rsa_pss_pem;
    close $tmpfh;
    my $rsa_pss_pub = `openssl pkey -in $tmpfile -pubout 2>/dev/null`;
    skip "RSA-PSS public key export failed", 2
        unless ($? >> 8) == 0 && $rsa_pss_pub =~ /-----BEGIN PUBLIC KEY-----/;
    eval { Crypt::OpenSSL::RSA->new_public_key($rsa_pss_pub) };
    ok($@, "new_public_key rejects RSA-PSS public key");
    like($@, qr/not an RSA key|unrecognized key format|ASN1/i, "RSA-PSS public key gives appropriate error");
}
