package Crypt::Perl::ECDSA::PublicKey;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::PublicKey - object representation of ECDSA public key

=head1 SYNOPSIS

    #Use Parse.pm or a private key’s get_public_key()
    #rather #than instantiating this class directly.

    #This works even if the object came from a key file that doesn’t
    #contain the curve name.
    $pbkey->get_curve_name();

    if ($payload > ($pbkey->max_sign_bits() / 8)) {
        die "Payload too long!";
    }

    $pbkey->verify($payload, $sig) or die "Invalid signature!";

    #For JSON Web Algorithms (JWT et al.), cf. RFC 7518 page 8
    #This verifies against the appropriate SHA digest rather than
    #against the original message.
    $pbkey->verify_jwa($payload, $sig) or die "Invalid signature!";

    #----------------------------------------------------------------------

    #Includes “kty”, “crv”, “x”, and “y”.
    #Add in whatever else your application needs afterward.
    #
    #This will die() if you try to run it with a curve that
    #doesn’t have a known JWK “crv” value.
    #
    my $pub_jwk = $pbkey->get_struct_for_public_jwk();

    #Useful for JWTs
    my $jwt_alg = $pbkey->get_jwa_alg();

=head1 DISCUSSION

The SYNOPSIS above should be illustration enough of how to use this class.

Export methods (PEM, DER, etc.) are shown in L<Crypt::Perl::ECDSA>.

=cut

use strict;
use warnings;

use parent qw( Crypt::Perl::ECDSA::KeyBase );

use Try::Tiny;

use Crypt::Perl::BigInt ();
use Crypt::Perl::ECDSA::ECParameters ();

use constant ASN1_PUBLIC => Crypt::Perl::ECDSA::KeyBase->ASN1_Params() . q<

    -- FG: For some reason just plain “AlgorithmIdentifier”
    -- causes the parser not to decode parameters.namedCurve.
    FG_AlgorithmIdentifier ::= SEQUENCE {
        algorithm   OBJECT IDENTIFIER,
        parameters  EcpkParameters
    }

    ECPublicKey ::= SEQUENCE {
        keydata     FG_AlgorithmIdentifier,
        publicKey   BIT STRING
    }
>;

use constant _PEM_HEADER => 'PUBLIC KEY';

#There’s no new_by_curve_name() method here because
#that logic in PrivateKey is only really useful for when we
#generate keys.

sub new {
    my ($class, $public, $curve_parts) = @_;

    my $self = bless {}, $class;

    $self->_set_public($public);

    return $self->_add_params( $curve_parts );
}

sub algorithm_identifier_with_curve_name {
    my ($self) = @_;

    return $self->_algorithm_identifier($self->_named_curve_parameters());
}

sub _algorithm_identifier {
    my ($self, $curve_parts) = @_;

    return {
        algorithm => Crypt::Perl::ECDSA::ECParameters::OID_ecPublicKey(),
        parameters => $curve_parts,
    };
}

sub _get_asn1_parts {
    my ($self, $curve_parts, @params) = @_;

    return $self->__to_der(
        'ECPublicKey',
        ASN1_PUBLIC(),
        {
            keydata => $self->_algorithm_identifier($curve_parts),
        },
        @params,
    );
}

1;
