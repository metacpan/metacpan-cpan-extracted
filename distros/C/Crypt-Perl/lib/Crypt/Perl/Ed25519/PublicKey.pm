package Crypt::Perl::Ed25519::PublicKey;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::Ed25519::PublicKey

=head1 SYNOPSIS

    # This requires an octet string.
    my $import_key = Crypt::Perl::Ed25519::PublicKey->new( $pub_str );

    $key->verify( $message, $signature ) or die "Invalid sig for msg!";

    #----------------------------------------------------------------------

    # Returns an octet string.
    my $pub_str = $key->get_public();

    # Returns an object
    my $pub_obj = $key->get_public_key();

    # This returns a hash reference, NOT a JSON string.
    my $pub_hr = $key->get_struct_for_public_jwk();

=head1 DESCRIPTION

This class implements Ed25519 verification.

=cut

use parent qw( Crypt::Perl::Ed25519::KeyBase );

sub new {
    my ($class, $pub) = @_;

    $class->_verify_binary_key_part($pub);

    return bless {
        _public => $pub,
        _public_ar => [ unpack 'C*', $pub ],
    }, $class;
}

use constant {
    _PEM_HEADER => 'PUBLIC KEY',
    _ASN1 => q<
        FG_Key ::= SEQUENCE {
            algorithmIdentifier AlgorithmIdentifier,
            subjectPublicKey    BIT STRING
        }
    >,
};

sub _to_der_args {
    my ($self) = @_;

    return (

        # The leading bytes are the encoding of the inner CurvePrivateKey
        # (i.e., OCTET STRING).
        subjectPublicKey => $self->{'_public'},
    );
}

1;
