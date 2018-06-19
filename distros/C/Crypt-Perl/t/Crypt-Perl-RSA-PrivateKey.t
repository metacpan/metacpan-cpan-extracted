package t::Crypt::Perl::RSA::PrivateKey;

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

use lib "$FindBin::Bin/lib";
use parent qw( TestClass );

use MIME::Base64 ();

use Crypt::Perl::BigInt ();
use Crypt::Perl::RSA::Parse ();
use Crypt::Perl::RSA::PrivateKey ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $self->_load_tests();

    local $@;
    $self->{'_has_ossl'} = eval { require Crypt::OpenSSL::RSA };

    $self->num_method_tests( 'do_RS256_tests', 5 * @{ $self->{'_tests'} } );

    return $self;
}

sub _load_tests {
    my ($self) = @_;

    open my $rfh, '<', "$FindBin::Bin/assets/RS256.dump";
    $self->{'_tests'} = do { local $/; <$rfh> };
    close $rfh;

    $self->{'_tests'} = eval $self->{'_tests'};

    return;
}

sub _display_raw {
    return sprintf( '%v02x', $_[0] );
}

sub test_get_jwk_thumbprint : Tests(2) {
    my $PEM = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIByQIBAAJhAKN4HLaYKxh5Z5In+3Yq3E1c7mAZZdsJlsrKU8pGt5GbmqKqADMX
DnMStnFFYQyI5QTUhT64vwL4HCokb+tE2Fxo8jpGXYwamHjx9/6EJQ8UIZ44Xa3X
335IVSB1sYAICwIDAQABAmAfsU/Pzty8F/2OhpXoKRMhJJ1KoGHw/4DuvB9WnjNE
1ag7VT5IqXWxtbUNbOgN6BQ/cjcMbyDjLoqSnflLWI1UnzEFF29OidgEqHO9n1dn
jjAxjFcXFtLwtxY9MGJ4iXECMQDOQvMLMI5ynR9mMpf8Yq6dS8ryllj0ucc3FMAl
rYcJCGbb1qKXCMuuEk5Dw33xts8CMQDK43uVC2gqf7OvgO+kDpiJY47BFwvs+91q
olZ4bb8g+MFVNZgLC1G3lvWmcfn+qgUCMEyyBk+l2YHyvMcyjuMxCn7AvREhKKiv
H81ycNRRxwFr11ttXv3MLnhmpCV8XqtvbwIwRcakeubYZT1UA7jZMdffN+jocJnH
fTJFvOWlzXcY83L5sp9i8fFrojMlup+aNa4tAjBSn1SfMwbITbFze0K0Ca0kVmsx
dfxraCy2A+tQkCpCYGo5NcFbEgc2MD3YzATmPg8=
-----END RSA PRIVATE KEY-----
END

    my $key = Crypt::Perl::RSA::Parse::private($PEM);

    throws_ok(
        sub { $key->get_jwk_thumbprint('isa') },
        'Crypt::Perl::X::UnknownHash',
        'reject faux hash names that are UNIVERSAL methods',
    );

    is(
        $key->get_jwk_thumbprint('sha256'),
        '8F9kce8-q3vfjOlDSBapPBVbzJVsKIdy6sD-hE-E83Y',
        'expected JWK thumbprint',
    );

    return;
}

sub test_jwk_methods : Tests(2) {

    #Taken from RFC 7517, page 25
    my $params = {
          modulus => '0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw',
          publicExponent => 'AQAB',
          privateExponent => 'X4cTteJY_gn4FYPsXB8rdXix5vwsg1FLN5E3EaG6RJoVH-HLLKD9M7dx5oo7GURknchnrRweUkC7hT5fJLM0WbFAKNLWY2vv7B6NqXSzUvxT0_YSfqijwp3RTzlBaCxWp4doFk5N2o8Gy_nHNKroADIkJ46pRUohsXywbReAdYaMwFs9tv8d_cPVY3i07a3t8MN6TNwm0dSawm9v47UiCl3Sk5ZiG7xojPLu4sbg1U2jx4IBTNBznbJSzFHK66jT8bgkuqsk0GjskDJk19Z4qwjwbsnn4j2WBii3RL-Us2lGVkY8fkFzme1z0HbIkfz0Y6mqnOYtqc0X4jfcKoAC8Q',
          prime1 => '83i-7IvMGXoMXCskv73TKr8637FiO7Z27zv8oj6pbWUQyLPQBQxtPVnwD20R-60eTDmD2ujnMt5PoqMrm8RfmNhVWDtjjMmCMjOpSXicFHj7XOuVIYQyqVWlWEh6dN36GVZYk93N8Bc9vY41xy8B9RzzOGVQzXvNEvn7O0nVbfs',
          prime2 => '3dfOR9cuYq-0S-mkFLzgItgMEfFzB2q3hWehMuG0oCuqnb3vobLyumqjVZQO1dIrdwgTnCdpYzBcOfW5r370AFXjiWft_NGEiovonizhKpo9VVS78TzFgxkIdrecRezsZ-1kYd_s1qDbxtkDEgfAITAG9LUnADun4vIcb6yelxk',
          exponent1 => 'G4sPXkc6Ya9y8oJW9_ILj4xuppu0lzi_H7VTkS8xj5SdX3coE0oimYwxIi2emTAue0UOa5dpgFGyBJ4c8tQ2VF402XRugKDTP8akYhFo5tAA77Qe_NmtuYZc3C3m3I24G2GvR5sSDxUyAN2zq8Lfn9EUms6rY3Ob8YeiKkTiBj0',
          exponent2 => 's9lAH9fggBsoFR8Oac2R_E2gw282rT2kGOAhvIllETE1efrA6huUUvMfBcMpn8lqeW6vzznYY5SSQF7pMdC_agI3nG8Ibp1BUb0JUiraRNqUfLhcQb_d9GF4Dh7e74WbRsobRonujTYN1xCaP6TO61jvWrX-L18txXw494Q_cgk',
          coefficient => 'GyM_p6JrXySiz1toFgKbWV-JdI3jQ4ypu9rbMWx3rQJBfmt0FoYzgUIZEVFEcOqwemRN81zoDAaa-Bk0KWNGDjJHZDdDmFhW3AN7lI-puxk_mHZGJ11rxyR8O55XLSe3SPmRfKwZI6yU24ZxvQKFYItdldUKGzO6Ia6zTKhAVRU',
    };

    my %orig = %$params;

    $_ = MIME::Base64::decode_base64url($_) for values %$params;
    $_ = Crypt::Perl::BigInt->from_bytes($_) for values %$params;

    my $prkey = Crypt::Perl::RSA::PrivateKey->new($params);

    my $pub_jwk = $prkey->get_struct_for_public_jwk();

    is_deeply(
        $pub_jwk,
        {
            kty => 'RSA',
            n => $orig{'modulus'},
            e => $orig{'publicExponent'},
        },
        'get_struct_for_public_jwk() gives the expected structure',
    );

    my $prv_jwk = $prkey->get_struct_for_private_jwk();

    is_deeply(
        $prv_jwk,
        {
            %$pub_jwk,
            d => $orig{'privateExponent'},
            p => $orig{'prime1'},
            q => $orig{'prime2'},
            dp => $orig{'exponent1'},
            dq => $orig{'exponent2'},
            qi => $orig{'coefficient'},
        },
        'get_struct_for_private_jwk() gives the expected structure',
    ) or diag explain $prv_jwk;

    return;
}

sub check_raw_encrypt_decrypt : Tests(2) {
    my ($self) = @_;

    my $msg = 'Hello. This is a test.';

    my $largest_pem = $self->{'_tests'}->[-1][1];
    my $key = Crypt::Perl::RSA::Parse::private($largest_pem);

    my $crypted = $key->encrypt_raw($msg);
    isnt( $crypted, $msg, 'encrypt_raw() changes the message');

    my $decrypted = $key->decrypt_raw($crypted);
    is( $decrypted, $msg, '… and decrypt_raw() undoes that change');

    return;
}

sub check_RS384_and_RS512 : Tests(6) {
    my ($self) = @_;

    my $largest_pem = $self->{'_tests'}->[-1][1];
    my $key = Crypt::Perl::RSA::Parse::private($largest_pem);

    for my $alg ( qw( RS384 RS512 ) ) {
        my $message = rand;

        my $signature = $key->can("sign_$alg")->( $key, $message );

        is(
            $key->can("verify_$alg")->( $key, $message, $signature ),
            1,
            "$alg: Perl verified Perl’s signature",
        );

        is(
            $key->can("verify_$alg")->( $key, $message, $key->can("sign_$alg")->( $key, "00$message" ) ),
            q<>,
            "$alg: Perl non-verified a wrong signature",
        );

        SKIP: {
            skip 'No Crypt::OpenSSL::RSA; skipping', 1 if !$self->{'_has_ossl'};

            my $rsa = Crypt::OpenSSL::RSA->new_private_key($largest_pem);
            $alg =~ m<([0-9]+)> or die "huh? $alg";
            $rsa->can("use_sha$1_hash")->($rsa);
            ok(
                $rsa->verify( $message, $signature ),
                "$alg: OpenSSL verified Perl’s signature",
            );
        }
    }

    return;
}

sub test_get_public_key : Tests(3) {
    my ($self) = @_;

    my $pem = $self->{'_tests'}[-1][1];
    my $prkey = Crypt::Perl::RSA::Parse::private($pem);

    my $pbkey = $prkey->get_public_key();
    isa_ok(
        $pbkey,
        'Crypt::Perl::RSA::PublicKey',
        'get_public_key() return',
    );

    is(
        $pbkey->modulus()->as_hex(),
        $prkey->modulus()->as_hex(),
        'modulus matches',
    );

    is(
        $pbkey->exponent()->as_hex(),
        $prkey->publicExponent()->as_hex(),
        '(public) exponent matches',
    );

    return;
}

sub test_pem_der_export : Tests(2) {
    my ($self) = @_;

    SKIP: {
        skip 'No Crypt::OpenSSL::RSA; skipping', $self->num_tests() if !$self->{'_has_ossl'};

        my $pem = $self->{'_tests'}[-1][1];
        my $der = Crypt::Format::pem2der($pem);

        my $prkey = Crypt::Perl::RSA::Parse::private($pem);

        is(
            sprintf("%v.02x", $prkey->to_der()),
            sprintf("%v.02x", $der),
            'to_der()',
        );

        is(
            sprintf("%v.02x", Crypt::Format::pem2der( $prkey->to_pem() )),
            sprintf("%v.02x", $der),
            'to_pem()',
        );
    }

    return;
}

sub do_RS256_tests : Tests() {
    my ($self) = @_;

    for my $t ( @{ $self->{'_tests'} } ) {
        my ($label, $key_pem, $message, $sig_b64) = @$t;

        my $ossl_sig = MIME::Base64::decode($sig_b64);

        my $key = Crypt::Perl::RSA::Parse::private($key_pem);

        is(
            $key->verify_RS256( $message, $ossl_sig ),
            1,
            "$label: Perl verified OpenSSL’s signature",
        );

        my $signature = $key->sign_RS256( $message );

        is(
            _display_raw($signature),
            _display_raw($ossl_sig),
            "$label: Perl’s signature is as expected",
        ) or do { diag $message; diag $key_pem };

        is(
            $key->verify_RS256( $message, $signature ),
            1,
            "$label: Perl verified Perl’s signature",
        );

        my $mangled_sig = reverse $signature;

        dies_ok(
            sub { $key->verify_RS256( $message, $mangled_sig ) },
            "$label: mangled signature non-verification",
        );

        SKIP: {
            skip 'No Crypt::OpenSSL::RSA; skipping', 1 if !$self->{'_has_ossl'};

            my $rsa = Crypt::OpenSSL::RSA->new_private_key($key_pem);
            $rsa->use_sha256_hash();
            ok(
                $rsa->verify( $message, $signature ),
                "$label: OpenSSL verified Perl’s signature",
            );
        }
    }

    return;
}
