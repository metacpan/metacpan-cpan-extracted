use strict;
use warnings;
use Test::More;

use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;

Crypt::OpenSSL::Random::random_seed("OpenSSL needs at least 32 bytes.");
Crypt::OpenSSL::RSA->import_random_seed();

plan tests => 10;

my $rsa_priv = Crypt::OpenSSL::RSA->generate_key(2048);
my $pub_pem  = $rsa_priv->get_public_key_string();
my $rsa_pub  = Crypt::OpenSSL::RSA->new_public_key($pub_pem);

# --- Private key: all 8 parameters must be defined ---

my @priv_params = eval { $rsa_priv->get_key_parameters() };
ok( !$@, "get_key_parameters on private key does not croak" )
    or diag "Error: $@";
is( scalar @priv_params, 8, "get_key_parameters returns 8 values" );

my ($n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp) = @priv_params;
ok( defined $n && defined $e,
    "private key: n and e are defined (mandatory public components)" );
ok( defined $d,
    "private key: d is defined (private exponent)" );
ok( defined $p && defined $q,
    "private key: p and q are defined (prime factors)" );
ok( defined $dmp1 && defined $dmq1 && defined $iqmp,
    "private key: CRT parameters are defined" );

# --- Public key: n and e defined, private components are undef ---

my @pub_params = eval { $rsa_pub->get_key_parameters() };
ok( !$@, "get_key_parameters on public key does not croak" )
    or diag "Error: $@";
is( scalar @pub_params, 8, "get_key_parameters returns 8 values for public key" );

my ($pn, $pe, $pd, $pp, $pq, $pdmp1, $pdmq1, $piqmp) = @pub_params;
ok( defined $pn && defined $pe,
    "public key: n and e are defined" );
ok( !defined $pd && !defined $pp && !defined $pq
    && !defined $pdmp1 && !defined $pdmq1 && !defined $piqmp,
    "public key: private components (d, p, q, CRT) are undef" );
