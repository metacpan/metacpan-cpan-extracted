package t::Crypt::Perl::Ed25519::Parse;

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Crypt::Format ();

use Crypt::Perl::Ed25519::Parse ();

my $private = <<END;
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIBmM4Bl8wys6doYGzCyFQ6Gvkc/6Ad8DpZCAvMYSGTO6
-----END PRIVATE KEY-----
END

my $priv_key = Crypt::Perl::Ed25519::Parse::private($private);

is(
    sprintf( '%v.02x', $priv_key->get_private() ),
    '19.8c.e0.19.7c.c3.2b.3a.76.86.06.cc.2c.85.43.a1.af.91.cf.fa.01.df.03.a5.90.80.bc.c6.12.19.33.ba',
    'parse private OK',
);

is(
    $priv_key->to_der(),
    Crypt::Format::pem2der($private),
    'private: round-trip to DER',
);

#----------------------------------------------------------------------

my $public = <<END;
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAGBpjxjhip9MvnhVGjfJaApjmPlPt5sd44SxKAJNvg5I=
-----END PUBLIC KEY-----
END

my $pub_key = Crypt::Perl::Ed25519::Parse::public($public);

is(
    sprintf( '%v.02x', $pub_key->get_public() ),
    '18.1a.63.c6.38.62.a7.d3.2f.9e.15.46.8d.f2.5a.02.98.e6.3e.53.ed.e6.c7.78.e1.2c.4a.00.93.6f.83.92',
    'parse public OK',
);

is(
    $pub_key->to_der(),
    Crypt::Format::pem2der($public),
    'public: round-trip to DER',
);

#----------------------------------------------------------------------

my $private_jwk = {
   kty => "OKP",
   crv => "Ed25519",
   d => "nWGxne_9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A",
   x => "11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo",
};

my $priv_jwk_obj = Crypt::Perl::Ed25519::Parse::jwk($private_jwk);
is(
    sprintf( '%v.02x', $priv_jwk_obj->get_private() ),
    '9d.61.b1.9d.ef.fd.5a.60.ba.84.4a.f4.92.ec.2c.c4.44.49.c5.69.7b.32.69.19.70.3b.ac.03.1c.ae.7f.60',
    'JTK: private key assembled correctly',
);
is(
    sprintf( '%v.02x', $priv_jwk_obj->get_public() ),
    'd7.5a.98.01.82.b1.0a.b7.d5.4b.fe.d3.c9.64.07.3a.0e.e1.72.f3.da.a6.23.25.af.02.1a.68.f7.07.51.1a',
    'JTK: private key has correct public component',
);

is_deeply(
    $priv_jwk_obj->get_struct_for_private_jwk(),
    $private_jwk,
    'JTK: private key parse-then-encode',
);

my $public_jwk = {
   kty => "OKP",
   crv => "Ed25519",
   x => "11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo",
};

my $pub_jwk_obj = Crypt::Perl::Ed25519::Parse::jwk($public_jwk);

is(
    sprintf( '%v.02x', $pub_jwk_obj->get_public() ),
    'd7.5a.98.01.82.b1.0a.b7.d5.4b.fe.d3.c9.64.07.3a.0e.e1.72.f3.da.a6.23.25.af.02.1a.68.f7.07.51.1a',
    'JTK: public key assembled correctly',
);

is_deeply(
    $pub_jwk_obj->get_struct_for_public_jwk(),
    $public_jwk,
    'JTK: public key parse-then-encode',
);

is_deeply(
    $priv_jwk_obj->get_struct_for_public_jwk(),
    $public_jwk,
    'JTK: private key parse-then-encode-as-public',
);

done_testing();
