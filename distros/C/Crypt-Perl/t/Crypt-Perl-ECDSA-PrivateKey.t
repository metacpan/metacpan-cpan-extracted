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
use Test::FailWarnings;
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

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    my $total_curves = @{ [ $class->_CURVE_NAMES() ] };

    $self->num_method_tests( 'test_sign', 24 * $total_curves );

    return $self;
}

sub _CURVE_NAMES {
    my $dir = "$FindBin::Bin/assets/ecdsa_explicit_compressed";

    opendir( my $dh, $dir );

    return sort map { m<(.+)\.key\z> ? $1 : () } readdir $dh;
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

sub test_sign_deterministic__specific : Tests(10) {
    my ($self) = @_;

    my $key_pem = <<END;
-----BEGIN EC PRIVATE KEY-----
MIHcAgEBBEIAv28oIsE2drCHfA3Jhkhc/kjsm2VcZywFpFAM1QuH/KmOu3iucI2r
Q/bz2G3Fqhg4gSOq4Wo/WNkF+2djB49fGmmgBwYFK4EEACOhgYkDgYYABAHP4J5m
Tvsh+RBJauItPWOOraBVslPOkAHp4aPHKKHCHSqvnc8Rd35hrd4qHGAEijehicrA
eXThDZUZ9ampjgdyNgDlsIIYpL/kS7Ryx9bujpTsDPEa3zsRFmftoAuteT45n8Is
X75cA6vjBy2iqZZDGCTCpB0qs8hakzocogUboszkzw==
-----END EC PRIVATE KEY-----
END

    my $key = Crypt::Perl::ECDSA::Parse::private($key_pem);

    my $msg = 'sample';

    # Generated with python-ecdsa:
    my @t = (
        [ sha1 => '3081880242013810418d469f68bc927377b736b8f0ebdb7461191375ec1aadafefa33841af408911c1f0b5d9c3760c61a998c062facf04bc36caa358b799e98d8ea5543a98fc28024201d8020ebc23387a5d6bc94f8fe2060052eb90f0fee21c66e73011c95f407fa5ae3114deba730aeead003291fe9a1cfd5077210556bf85af38ea58e04f09c54fc819' ],
        [ sha224 => '3081880242010cbfcdf601b4d21de4fec949897d137c8de88ef462030d5010758a00ac151b1ce613d2b90e768454b618386ffbb9cdeb12121d910da25fd2d23965bf1501f7538b024201a2a9245c82506418333ed10933762741da7141371a48db3535d455037f1d14304158ef5c113cc9b11172432492b5e8d8989c1c40984741425451ddff94f4b0d525' ],
        [ sha256 => '308187024150905e2399a61e80b74bd49b9bacfebc1fa15d994c0a56bb98534e14831d915abc425fa2735d3b832661baf4af9627a10ebed2f5e6c449837e3646209e61bcc9df0242012ba95f06ca4659f09c7e2e87e16cc130513fef55c56b643cf6115d27609aedc005073a189816d12911c867d35adcc8185934dacf660c5d10049175532b8b0a9a60' ],
        [ sha384 => '30818802420087e28d2067c922fd3a2856e82bfef3a3f1bbcc077bf4fb5f5c375b4b210b11f71e681b7181896fe15d14d672871c3a597e7a8d847131f7d164fc567c34c0fb1160024200a5e925c61532fe22562cbc1fe6121767f75115fe5ef77c8641a339ffe069e800ff20dad1ba886dae2e9787c8cfb44c5d8df7e3f87f39ba374e1ddf7e8a5dbb405e' ],
        [ sha512 => '3081880242008d031ef7ce25ae7f93769597037d5c53ca3a597938b30957039641b2186268b21e96e7d4c30de0f605537d129d14e2d32df137dfea3d9b6c449bf2eb4137dd0520024201ddec83a86f556cf87d2137f8ef47ebb58ffb70211254a42a22bd49d151fce663a33ca0f4036acee2478b145bae7e19a2f1aeeab2241c5792fc2dbdad383a2be434' ],
    );

    for my $tt (@t) {
        my ($hashfn, $sig) = @$tt;

        my $fn = "sign_$hashfn";
        my $got_sig = $key->$fn($msg);

        is(
            unpack('H*', $got_sig),
            $sig,
            "$hashfn: deterministic signature matches from python-ecdsa",
        );

        ok(
            $key->verify( Digest::SHA->can($hashfn)->($msg), $got_sig ),
            "$hashfn: self-verify",
        );
    }

    return;
}

sub test_sign : Tests() {
    my ($self) = @_;

    diag "---------- This test takes a while and spews a lot of text.";

    my $msg = 'Hello-' . rand;

    diag "Message: [$msg]";

    #Use SHA1 since it’s the smallest digest that the latest OpenSSL accepts.
    my $dgst = Digest::SHA::sha1($msg);
    my $digest_alg = 'sha1';

    my %SKIPPED;

    for my $param_enc ( qw( named_curve explicit ) ) {
        for my $conv_form ( qw( compressed uncompressed hybrid ) ) {
            my $dir = "$FindBin::Bin/assets/ecdsa_${param_enc}_$conv_form";

            opendir( my $dh, $dir );

            for my $node ( sort readdir $dh ) {
                next if $node !~ m<(.+)\.key\z>;

                my $curve = $1;

                my $curve_label = "$curve ($param_enc, $conv_form public point)";

                diag $curve_label;

                SKIP: {
                    my $pkey_pem = File::Slurp::read_file("$dir/$node");

                    my $ecdsa;
                    try {
                        $ecdsa = Crypt::Perl::ECDSA::Parse::private($pkey_pem);
                    }
                    catch {
                        my $ok = try { $_->isa('Crypt::Perl::X::ECDSA::CharacteristicTwoUnsupported') };
                        $ok ||= try { $_->isa('Crypt::Perl::X::ECDSA::NoCurveForOID') };

                        if ($ok) {
                            $SKIPPED{$curve_label} = ref;
                            skip $_->to_string(), 4;
                        }

                        local $@ = $_;
                        die;
                    };

                    my ($signature, $det_signature);

                    try {
                        $signature = $ecdsa->sign($dgst);
                        diag "Random Sig: " . unpack('H*', $signature);

                        my $fn = "sign_$digest_alg";
                        $det_signature = $ecdsa->$fn($msg);
                        diag "Deterministic Sig: " . unpack('H*', $det_signature);
                    }
                    catch {
                        if ( try { $_->isa('Crypt::Perl::X::TooLongToSign') } ) {
                            $SKIPPED{$curve_label} = ref;
                            skip $_->to_string(), 4;
                        }

                        local $@ = $_;
                        die;
                    };

                    my @sub_t = (
                        [ random => $signature ],
                        [ deterministic => $det_signature ],
                    );

                    for my $st_ar (@sub_t) {
                        my ($label, $signature) = @$st_ar;

                        ok(
                            $ecdsa->verify( $dgst, $signature ),
                            "$curve, $param_enc parameters, $conv_form, $label signature: self-verify",
                        );

                      SKIP: {
                            if (!OpenSSL_Control::can_ecdsa()) {
                                $SKIPPED{$curve_label} = '!can_ecdsa';
                                skip 'Your OpenSSL can’t ECDSA!', 1;
                            }

                            my $explicit_pem = $ecdsa->to_pem_with_explicit_curve();

                            # Some OpenSSLs (e.g. RHEL 9’s) can load
                            # explicit-curve keys but refuse to work with them.
                            # To detect that we have OpenSSL create a dummy
                            # signature before using it to verify a
                            # Crypt::Perl-generated signature.
                            #
                            if (!OpenSSL_Control::can_sign_with_key($explicit_pem)) {
                                $SKIPPED{$curve_label} = '!can_sign_with_key';
                                skip 'Your OpenSSL can’t sign with this key!', 1;
                            }

                            if (OpenSSL_Control::has_ecdsa_verify_private_bug()) {
                                $SKIPPED{$curve_label} = 'has_ecdsa_verify_private_bug';
                                skip 'Your OpenSSL can’t correctly verify an ECDSA digest against a private key!', 1;
                            }

                            my $ok = OpenSSL_Control::verify_private(
                                $explicit_pem,
                                $msg,
                                $digest_alg,
                                $signature,
                            );

                            ok( $ok, "$curve, $param_enc parameters, $conv_form, $label signature: OpenSSL binary verifies our digest signature for “$msg” ($digest_alg)" );
                        }
                    }
                }
            }
        }
    }

    diag explain \%SKIPPED if %SKIPPED;

    return;
}

sub test_jwa : Tests(9) {
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

        my $sig2 = $key->sign_jwa($msg);
        is( $sig2, $sig, 'signature is constant for message' );

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
