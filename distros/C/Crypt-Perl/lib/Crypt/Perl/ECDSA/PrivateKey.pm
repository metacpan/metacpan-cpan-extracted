package Crypt::Perl::ECDSA::PrivateKey;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::PrivateKey - object representation of ECDSA private key

=head1 SYNOPSIS

    #Use Generate.pm or Parse.pm rather
    #than instantiating this class directly.

    #This works even if the object came from a key file that doesn’t
    #contain the curve name.
    $prkey->get_curve_name();

    if ($payload > ($prkey->max_sign_bits() / 8)) {
        die "Payload too long!";
    }

    #$payload is probably a hash (e.g., SHA-256) of your original message.
    my $sig = $prkey->sign($payload);

    #For JSON Web Algorithms (JWT et al.), cf. RFC 7518 page 8
    #This will also apply the appropriate SHA algorithm before signing.
    my $sig_jwa = $prkey->sign_jwa($payload);

    $prkey->verify($payload, $sig) or die "Invalid signature!";
    $prkey->verify_jwa($payload, $sig_jwa) or die "Invalid signature!";

    #Corresponding “der” methods exist as well.
    my $cn_pem = $prkey->to_pem_with_curve_name();
    my $expc_pem = $prkey->to_pem_with_explicit_curve();

    #----------------------------------------------------------------------

    my $pbkey = $prkey->get_public_key();

    #----------------------------------------------------------------------

    #Includes “kty”, “crv”, “x”, “y”, and (for private) “d”.
    #Add in whatever else your application needs afterward.
    #
    #These will die() if you try to run it with a curve that
    #doesn’t have a known JWK “crv” value.
    #
    my $prv_jwk = $prkey->get_struct_for_private_jwk();
    my $pub_jwk = $prkey->get_struct_for_public_jwk();

    #Useful for JWTs
    my $jwt_alg = $pbkey->get_jwa_alg();

=head1 DISCUSSION

The SYNOPSIS above should be illustration enough of how to use this class.

=head1 SECURITY

The security advantages of elliptic-curve cryptography (ECC) are a matter of
some controversy. While the math itself is apparently bulletproof, there are
varying opinions about the integrity of the various curves that are recommended
for ECC. Some believe that some curves contain “backdoors” that would allow
L<NIST|https://www.nist.gov> to sniff a transmission.

That said, RSA will eventually no longer be viable: as the keys get bigger, the
security advantage of increasing their size diminishes.

=head1 TODO

This minimal set of functionality can be augmented as feature requests come in.
Patches are welcome—particularly with tests!

=cut

use strict;
use warnings;

use parent qw( Crypt::Perl::ECDSA::KeyBase );

use Try::Tiny;

use Bytes::Random::Secure::Tiny ();

use Crypt::Perl::ASN1 ();
use Crypt::Perl::BigInt ();
use Crypt::Perl::Math ();
use Crypt::Perl::ToDER ();
use Crypt::Perl::X ();

#This is not the standard ASN.1 template as found in RFC 5915,
#but it seems to generate equivalent results.
#
use constant ASN1_PRIVATE => Crypt::Perl::ECDSA::KeyBase->ASN1_Params() . q<

    ECPrivateKey ::= SEQUENCE {
        version         INTEGER,
        privateKey      OCTET STRING,
        parameters      [0] EXPLICIT EcpkParameters OPTIONAL,
        publicKey       [1] EXPLICIT BIT STRING
    }
>;

use constant _PEM_HEADER => 'EC PRIVATE KEY';

use constant NUMBER_CLASS => 'Crypt::Perl::BigInt';

#$curve_parts is also a hash ref, defined as whatever the ASN.1
#parse of the main key’s “parameters” returned, whether that be
#explicit key parameters or a named curve.
#
sub new {
    my ($class, $key_parts, $curve_parts) = @_;

    if (!length $key_parts->{'version'}) {
        die Crypt::Perl::X::create('Generic', 'Need a “version”! (Try 1)');
    }

    my $self = {
        version => $key_parts->{'version'},
    };

    bless $self, $class;

    $self->_set_public( $key_parts->{'public'} );

    for my $k ( qw( private ) ) {
        if ( try { $key_parts->{$k}->isa(NUMBER_CLASS()) } ) {
            $self->{$k} = $key_parts->{$k};
        }
        else {
            die Crypt::Perl::X::create('Generic', sprintf "“$k” must be “%s”, not “$key_parts->{$k}”!", NUMBER_CLASS());
        }
    }

    return $self->_add_params( $curve_parts );
}

sub sign {
    return $_[0]->_sign_and_serialize($_[1]);
}

sub _sign_and_serialize {
    my ($self, $whatsit, $hashfn) = @_;

    my ($r, $s) = $self->_sign($whatsit, $hashfn);
    return $self->_serialize_sig( $r, $s );
}

sub _hash_sign_and_serialize {
    my ($self, $whatsit, $hashfn) = @_;

    require Digest::SHA;
    $whatsit = Digest::SHA->can($hashfn)->($whatsit);

    return $self->_sign_and_serialize($whatsit, $hashfn);
}

sub sign_sha1 {
    my ($self, $whatsit) = @_;

    return $_[0]->_hash_sign_and_serialize($whatsit, 'sha1');
}

sub sign_sha224 {
    my ($self, $whatsit) = @_;

    return $_[0]->_hash_sign_and_serialize($whatsit, 'sha224');
}

sub sign_sha256 {
    my ($self, $whatsit) = @_;

    return $_[0]->_hash_sign_and_serialize($whatsit, 'sha256');
}

sub sign_sha384 {
    my ($self, $whatsit) = @_;

    return $_[0]->_hash_sign_and_serialize($whatsit, 'sha384');
}

sub sign_sha512 {
    my ($self, $whatsit) = @_;

    return $_[0]->_hash_sign_and_serialize($whatsit, 'sha512');
}

#cf. RFC 7518, page 8
sub sign_jwa {
    my ($self, $whatsit) = @_;

    # As of version 0.34 this method creates deterministic signatures.

    my $dgst_name = $self->_get_jwk_digest_name();

    require Digest::SHA;
    $whatsit = Digest::SHA->can($dgst_name)->($whatsit);

    my ($r, $s) = map { $_->as_bytes() } $self->_sign($whatsit, $dgst_name);

    my $octet_length = Crypt::Perl::Math::ceil($self->max_sign_bits() / 8);

    substr( $_, 0, 0 ) = "\0" x ($octet_length - length) for ($r, $s);

    return $r . $s;
}

sub get_public_key {
    my ($self) = @_;

    require Crypt::Perl::ECDSA::PublicKey;

    my $curve_hr = $self->_explicit_curve_parameters( seed => 1 );
    my $ccurve_hr = $curve_hr->{'ecParameters'}{'curve'};
    $ccurve_hr->{'seed'} = [ $ccurve_hr->{'seed'} ];

    return Crypt::Perl::ECDSA::PublicKey->new(
        $self->_decompress_public_point(),
        $curve_hr,
    );
}

sub get_struct_for_private_jwk {
    my ($self) = @_;

    my $hr = $self->get_struct_for_public_jwk();

    require MIME::Base64;

    $hr->{'d'} = MIME::Base64::encode_base64url( $self->{'private'}->as_bytes() );

    return $hr;
}

#----------------------------------------------------------------------

#$whatsit is probably a message digest, e.g., from SHA256
sub _sign {
    my ($self, $whatsit, $det_hashfuncname) = @_;

    my $dgst = Crypt::Perl::BigInt->from_bytes( $whatsit );

    my $priv_num = $self->{'private'}; #Math::BigInt->from_hex( $priv_hex );

    my $n = $self->_curve()->{'n'}; #$curve_data->{'n'};

    my $key_len = $self->max_sign_bits();
    my $dgst_len = $dgst->bit_length();
    if ( $dgst_len > $key_len ) {
        die Crypt::Perl::X::create('TooLongToSign', $key_len, $dgst_len );
    }

    #isa ECPoint
    my $G = $self->_G();
    my ($k, $r);

    do {
        if ($det_hashfuncname) {
            require Crypt::Perl::ECDSA::Deterministic;
            $k = Crypt::Perl::ECDSA::Deterministic::generate_k(
                $n,
                $priv_num,
                $whatsit,
                $det_hashfuncname,
            );
        }
        else {
            $k = Crypt::Perl::Math::randint($n);
        }

        my $Q = $G->multiply($k);   #$Q isa ECPoint

        $r = $Q->get_x()->to_bigint()->copy()->bmod($n);
    } while !$r->is_positive();

    my $s = $k->bmodinv($n);

    #$s *= ( $dgst + ( $priv_num * $r ) );
    $s->bmul( $priv_num->copy()->bmuladd( $r, $dgst ) );

    $s->bmod($n);

    return ($r, $s);
}

sub _get_asn1_parts {
    my ($self, $curve_parts, @params) = @_;

    my $private_str = $self->{'private'}->as_bytes();

    return $self->__to_der(
        'ECPrivateKey',
        ASN1_PRIVATE(),
        {
            version => 1,
            privateKey => $private_str,
            parameters => $curve_parts,
        },
        @params,
    );
}

sub _serialize_sig {
    my ($self, $r, $s) = @_;

    my $asn1 = Crypt::Perl::ASN1->new()->prepare( $self->ASN1_SIGNATURE() );
    return $asn1->encode( r => $r, s => $s );
}

1;
