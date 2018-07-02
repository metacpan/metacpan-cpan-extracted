package t::Crypt::Perl::ECDSA::PrivateKey;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use Try::Tiny;

use FindBin;

use lib "$FindBin::Bin/lib";
use OpenSSL_Control ();

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

use lib "$FindBin::Bin/../lib";

use Crypt::Perl::ECDSA::EC::DB ();
use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::ECDSA::Parse ();
use Crypt::Perl::ECDSA::PublicKey ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $self->num_method_tests( 'test_sign', 12 * @{ [ $class->_CURVE_NAMES() ] } );

    return $self;
}

sub _CURVE_NAMES {
    my $dir = "$FindBin::Bin/assets/ecdsa_explicit_compressed";

    opendir( my $dh, $dir );

    return map { m<(.+)\.key\z> ? $1 : () } readdir $dh;
}

sub test_get_public_key : Tests(1) {
    my $key_path = "$FindBin::Bin/assets/prime256v1.key";

    my $key_str = File::Slurp::read_file($key_path);

    my $key_obj = Crypt::Perl::ECDSA::Parse::private($key_str);

    my $public = $key_obj->get_public_key();

    my $msg = 'Hello';

    my $sig = $key_obj->sign($msg);

    ok( $public->verify($msg, $sig), 'get_public_key() produces a working public key' );

    return;
}

sub test_to_der : Tests(2) {
    my $key_path = "$FindBin::Bin/assets/prime256v1.key";

    my $key_str = File::Slurp::read_file($key_path);

    my $key_obj = Crypt::Perl::ECDSA::Parse::private($key_str);

    my $der = $key_obj->to_der_with_curve_name();

    my $ossl_der = Crypt::Format::pem2der($key_str);
    is(
        $der,
        $ossl_der,
        'to_der_with_curve_name() yields same output as OpenSSL',
    ) or do { diag unpack( 'H*', $_ ) for ($der, $ossl_der) };

    #----------------------------------------------------------------------

    $key_path = "$FindBin::Bin/assets/prime256v1_explicit.key";
    $key_str = File::Slurp::read_file($key_path);
    $key_obj = Crypt::Perl::ECDSA::Parse::private($key_str);

    my $explicit_der = $key_obj->to_der_with_explicit_curve();
    $ossl_der = Crypt::Format::pem2der($key_str);

    is(
        $explicit_der,
        $ossl_der,
        'to_der_with_explicit_curve() matches OpenSSL, too',
    ) or do { diag unpack( 'H*', $_ ) for ($der, $ossl_der) };

    #print Crypt::Format::der2pem($explicit_der, 'EC PRIVATE KEY') . $/;

    return;
}

sub test_seed : Tests(2) {
    my $pem = File::Slurp::read_file("$FindBin::Bin/assets/ecdsa_named_curve_compressed/secp112r1.key");
    my $key = Crypt::Perl::ECDSA::Parse::private($pem);

    my $curve_data = Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name('secp112r1');
    my $seed_hex = substr( $curve_data->{'seed'}->as_hex(), 2 );

    my $der_hex = unpack 'H*', $key->to_der_with_explicit_curve();

    unlike( $der_hex, qr<\Q$seed_hex\E>, 'seed is NOT in explicit parameters by default' );

    $der_hex = unpack 'H*', $key->to_der_with_explicit_curve( seed => 1 );

    like( $der_hex, qr<\Q$seed_hex\E>, 'seed is in explicit parameters by request' );

    return;
}

sub test_sign : Tests() {
    my ($self) = @_;

    diag "XXX NOTE: This test can take a while and/or spew a lot of text.";

    my $msg = 'Hello' . rand;

    #Use SHA1 since it’s the smallest digest that the latest OpenSSL accepts.
    my $dgst = Digest::SHA::sha1($msg);
    my $digest_alg = 'sha1';

    for my $param_enc ( qw( named_curve explicit ) ) {
        for my $conv_form ( qw( compressed uncompressed hybrid ) ) {
            my $dir = "$FindBin::Bin/assets/ecdsa_${param_enc}_$conv_form";

            opendir( my $dh, $dir );

            for my $node ( readdir $dh ) {
                next if $node !~ m<(.+)\.key\z>;

                my $curve = $1;

                SKIP: {
                    note "$curve ($param_enc, $conv_form public point)";

                    my $pkey_pem = File::Slurp::read_file("$dir/$node");

                    my $ecdsa;
                    try {
                        $ecdsa = Crypt::Perl::ECDSA::Parse::private($pkey_pem);
                    }
                    catch {
                        my $ok = try { $_->isa('Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported') };
                        $ok ||= try { $_->isa('Crypt::Perl::X::ECDSA::NoCurveForOID') };

                        skip $_->to_string(), 2 if $ok;

                        local $@ = $_;
                        die;
                    };

                    #my $hello = $ecdsa->sign('Hello');
                    #note unpack( 'H*', $hello );
                    #note explain [ map { $_->as_hex(), $_->bit_length() } values %{ Crypt::Perl::ASN1->new()->prepare(Crypt::Perl::ECDSA::KeyBase::ASN1_SIGNATURE())->decode( $hello ) } ];

                    #note "Key Prv: " . $ecdsa->{'private'}->as_hex();
                    #note "Key Pub: " . $ecdsa->{'public'}->as_hex();

                    try {
                        my $signature = $ecdsa->sign($dgst);

                        note "Sig: " . unpack('H*', $signature);

                        ok(
                            $ecdsa->verify( $dgst, $signature ),
                            "$curve, $param_enc parameters, $conv_form: self-verify",
                        );

                    SKIP: {
                            skip 'Your OpenSSL can’t ECDSA!', 1 if !OpenSSL_Control::can_ecdsa();

                            skip 'Your OpenSSL can’t load this key!', 1 if !OpenSSL_Control::can_load_private_pem($ecdsa->to_pem_with_explicit_curve());

                            skip 'Your OpenSSL can’t correct verify an ECDSA digest against a private key!', 1 if OpenSSL_Control::has_ecdsa_verify_private_bug();

                            my $ok = OpenSSL_Control::verify_private(
                                $ecdsa->to_pem_with_explicit_curve(),
                                $msg,
                                $digest_alg,
                                $signature,
                            );

                            ok( $ok, "$curve, $param_enc parameters, $conv_form: OpenSSL binary verifies our digest signature for “$msg” ($digest_alg)" );
                        }
                    }
                    catch {
                        if ( try { $_->isa('Crypt::Perl::X::TooLongToSign') } ) {
                            skip $_->to_string(), 2;
                        }

                        local $@ = $_;
                        die;
                    };
                }
            }
        }
    }

    return;
}

sub test_jwa : Tests(6) {
    my ($self) = @_;

    my %curve_dgst = (
        prime256v1 => 'sha256',
        secp384r1 => 'sha384',
        secp521r1 => 'sha512',
    );

    for my $curve ( sort keys %curve_dgst ) {
        my $msg = rand;
        note "Message: [$msg]";

        $curve =~ m<([0-9]+)> or die '??';
        my $dgst = Digest::SHA::sha256($msg);

        my $key = Crypt::Perl::ECDSA::Generate::by_name($curve);
        note $key->to_pem_with_curve_name();

        my $sig = $key->sign_jwa($msg);
        note( "Signature: " . unpack 'H*', $sig );

        is(
            $key->verify_jwa($msg, $sig),
            1,
            "$curve: self-verify",
        );

        SKIP: {
            eval 'require Crypt::PK::ECC' or skip 'No Crypt::PK::ECC', 1;

            my $pk = Crypt::PK::ECC->new( \($key->to_pem_with_explicit_curve()) );
            ok(
                $pk->verify_message_rfc7518($sig, $msg, $curve_dgst{$curve}),
                "$curve: Crypt::PK::ECC verifies what we produced",
            );
        }
    }
}

#cf. RFC 7517, page 25
sub test_jwk : Tests(3) {
    my %params = (
        version => 1,
        public => Crypt::Perl::BigInt->from_bytes( "\x04" . MIME::Base64::decode_base64url('MKBCTNIcKUSDii11ySs3526iDZ8AiTo7Tu6KPAqv7D4') . MIME::Base64::decode_base64url('4Etl6SRW2YiLUrN5vfvVHuhp7x8PxltmWWlbbM4IFyM') ),
        private => Crypt::Perl::BigInt->from_bytes( MIME::Base64::decode_base64url('870MB6gfuTJ4HtUnUvYMyJpr5eUZNP4Bk43bVdj3eAE') ),
    );

    my $prkey = Crypt::Perl::ECDSA::PrivateKey->new_by_curve_name(
        \%params,
        'prime256v1',
    );

    my $pub_jwk = $prkey->get_struct_for_public_jwk();

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

    my $prv_jwk = $prkey->get_struct_for_private_jwk();

    is_deeply(
        $prv_jwk,
        {
            %$expected_pub,
            d => "870MB6gfuTJ4HtUnUvYMyJpr5eUZNP4Bk43bVdj3eAE",
        },
        'get_struct_for_private_jwk()',
    );

    #from Crypt::PK::ECC
    my $sha512_thumbprint = '87wrLaz3s_FhzVDc1S8PBGMBK7SlogjruZ8x3hrvMMS28Zq4-1ugZG2qoqUcBatvWxzlCLGqHCRv4eVefHCsyg';

    is(
        $prkey->get_jwk_thumbprint('sha512'),
        $sha512_thumbprint,
        'to_jwk_thumbprint(sha512)',
    );

    return;
}

sub test_verify : Tests(2) {
    my ($self) = @_;

    my $key_path = "$FindBin::Bin/assets/prime256v1.key";

    my $pkey_pem = File::Slurp::read_file($key_path);

    my $ecdsa = Crypt::Perl::ECDSA::Parse::private($pkey_pem);

    my $msg = 'Hello';

    my $sig = pack 'H*', '3046022100e3d248766709081d22f1c2762a79ac1b5e99edc2fe147420e1131cb207859300022100ad218584c31c55b2a15d1598b00f425bfad41b3f3d6a4eec620cc64dfc931848';

    is(
        $ecdsa->verify( $msg, $sig ),
        1,
        'verify() - positive',
    );

    my $bad_sig = $sig;
    $bad_sig =~ s<.\z><9>;

    is(
        $ecdsa->verify( $msg, $bad_sig ),
        0,
        'verify() - negative',
    );

    return;
}

sub _key_for_test_compressed {
    my ($self, $pem) = @_;
    return Crypt::Perl::ECDSA::Parse::private($pem);
}

1;
