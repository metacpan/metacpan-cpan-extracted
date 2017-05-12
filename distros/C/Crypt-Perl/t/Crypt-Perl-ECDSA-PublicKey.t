package t::Crypt::Perl::ECDSA::PublicKey;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use Crypt::Format ();
use Digest::SHA ();
use File::Slurp ();
use File::Temp ();
use MIME::Base64 ();

use lib "$FindBin::Bin/lib";

use parent qw(
    ECDSAKeyTest
);

use Crypt::Perl::ECDSA::EC::DB ();
use Crypt::Perl::ECDSA::Parse ();
use Crypt::Perl::ECDSA::PublicKey ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub _key_for_test_compressed {
    my ($self) = @_;

    my $uncompressed_pem = $self->PEM_FOR_COMPRESSED_TEST();
    my $prkey = Crypt::Perl::ECDSA::Parse::private($uncompressed_pem);
    return $prkey->get_public_key();
}

sub test_seed : Tests(2) {
    my $curve_data = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name('secp112r1');
    my $seed_hex = substr( $curve_data->{'seed'}->as_hex(), 2 );

    my $pem = File::Slurp::read_file("$FindBin::Bin/assets/ecdsa_named_curve_compressed/secp112r1.key");
    my $prkey = Crypt::Perl::ECDSA::Parse::private($pem);
    my $key = $prkey->get_public_key();

    my $der_hex = unpack 'H*', $key->to_der_with_explicit_curve();

    unlike( $der_hex, qr<\Q$seed_hex\E>, 'seed is NOT in explicit parameters by default' );

    $der_hex = unpack 'H*', $key->to_der_with_explicit_curve( seed => 1 );

    like( $der_hex, qr<\Q$seed_hex\E>, 'seed is in explicit parameters by request' );

    return;
}

#cf. RFC 7517, page 25
sub test_jwk : Tests(2) {
    my $pbkey = Crypt::Perl::ECDSA::PublicKey->new_by_curve_name(
        Crypt::Perl::BigInt->from_bytes( "\x04" . MIME::Base64::decode_base64url('MKBCTNIcKUSDii11ySs3526iDZ8AiTo7Tu6KPAqv7D4') . MIME::Base64::decode_base64url('4Etl6SRW2YiLUrN5vfvVHuhp7x8PxltmWWlbbM4IFyM') ),
        'prime256v1',
    );

    my $pub_jwk = $pbkey->get_struct_for_public_jwk();

    my $expected_pub = {
        kty => "EC",
        crv => "P-256",
        x => "MKBCTNIcKUSDii11ySs3526iDZ8AiTo7Tu6KPAqv7D4",
        y => "4Etl6SRW2YiLUrN5vfvVHuhp7x8PxltmWWlbbM4IFyM",
    };

    is_deeply(
        $pub_jwk,
        $expected_pub,
        'get_struct_for_public_jwk()',
    ) or diag explain $pub_jwk;

    #from Crypt::PK::ECC
    my $sha384_thumbprint = 'bLeg0iV0lOxemYi1inZct_fpBVGT0PjmOJfkLKNQzwiVJph-qr70kbtxqtdk9pVx';

    is(
        $pbkey->get_jwk_thumbprint('sha384'),
        $sha384_thumbprint,
        'to_jwk_thumbprint(sha384)',
    );

    return;
}

sub test_subject_public_key : Tests(1) {
    my ($self) = @_;

    my $key_path = "$FindBin::Bin/assets/prime256v1.key.public";

    my $pem = File::Slurp::read_file($key_path);

    $pem = Crypt::Format::pem2der($pem);

    isa_ok(
        Crypt::Perl::ECDSA::Parse::public($pem),
        'Crypt::Perl::ECDSA::PublicKey',
        'public key parse',
    );

    return;
}

sub test_to_der_with_explicit_curve : Tests(1) {
    my $key_path = "$FindBin::Bin/assets/prime256v1_explicit.key.public";

    my $pkey_pem = File::Slurp::read_file($key_path);
    my $der1 = Crypt::Format::pem2der($pkey_pem);

    my $ecdsa = Crypt::Perl::ECDSA::Parse::public($pkey_pem);

    my $der2 = $ecdsa->to_der_with_explicit_curve();

    $_ = unpack('H*', $_) for $der2, $der1;

    is(
        $der2,
        $der1,
        'output DER matches the input',
    );

    return;
}

sub test_to_der_with_curve_name : Tests(1) {
    my $key_path = "$FindBin::Bin/assets/prime256v1.key.public";

    my $pkey_pem = File::Slurp::read_file($key_path);
    my $der1 = Crypt::Format::pem2der($pkey_pem);

    my $ecdsa = Crypt::Perl::ECDSA::Parse::public($pkey_pem);

    my $der2 = $ecdsa->to_der_with_curve_name();

    $_ = unpack('H*', $_) for $der2, $der1;

    is(
        $der2,
        $der1,
        'output DER matches the input',
    );

    return;
}

sub test_verify : Tests(14) {
    my ($self) = @_;

    my $key_path = "$FindBin::Bin/assets/prime256v1.key.public";

    my $pkey_pem = File::Slurp::read_file($key_path);

    my $ossl_ecdsa = Crypt::Perl::ECDSA::Parse::public($pkey_pem);

    #“rt” for “round-trip”
    my %keys = (
        rt_curve_name => $ossl_ecdsa->to_pem_with_curve_name(),
        rt_curve_name_compressed => $ossl_ecdsa->to_pem_with_curve_name( compressed => 1),
        rt_explicit_curve => $ossl_ecdsa->to_pem_with_explicit_curve(),
        rt_explicit_curve_compressed => $ossl_ecdsa->to_pem_with_explicit_curve( compressed => 1 ),
        rt_explicit_curve_with_seed => $ossl_ecdsa->to_pem_with_explicit_curve( seed => 1 ),
        rt_explicit_curve_compressed_with_seed => $ossl_ecdsa->to_pem_with_explicit_curve( seed => 1, compressed => 1 ),
    );

    $_ = Crypt::Perl::ECDSA::Parse::public($_) for values %keys;

    $keys{'from_openssl'} = $ossl_ecdsa;

    my $msg = 'Hello';

    my $sig = pack 'H*', '3046022100e3d248766709081d22f1c2762a79ac1b5e99edc2fe147420e1131cb207859300022100ad218584c31c55b2a15d1598b00f425bfad41b3f3d6a4eec620cc64dfc931848';

    while ( my ($name, $ecdsa) = each %keys ) {
        is(
            $ecdsa->verify( $msg, $sig ),
            1,
            "$name: verify() - positive",
        );

        my $bad_sig = $sig;
        $bad_sig =~ s<.\z><9>;

        is(
            $ecdsa->verify( $msg, $bad_sig ),
            0,
            "$name: verify() - negative",
        );
    }

    return;
}

1;
