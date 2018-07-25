package Crypt::Perl::RSA::KeyBase;

use strict;
use warnings;

use parent qw(
    Class::Accessor::Fast
    Crypt::Perl::KeyBase
);

use Module::Load ();

use Crypt::Perl::BigInt ();
use Crypt::Perl::X ();

BEGIN {
    __PACKAGE__->mk_ro_accessors('modulus');
    __PACKAGE__->mk_ro_accessors('publicExponent');

    *N = \&modulus;
    *E = \&publicExponent;
}

use constant _JWK_THUMBPRINT_JSON_ORDER => qw( e kty n );

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $self->{'publicExponent'} = Crypt::Perl::BigInt->new( $self->{'publicExponent'} );

    return $self;
}

sub to_pem {
    my ($self) = @_;

    require Crypt::Format;
    return Crypt::Format::der2pem( $self->to_der(), $self->_PEM_HEADER() );
}

#i.e., modulus length, in bits
sub size {
    my ($self) = @_;

    return length( $self->modulus()->as_bin() ) - 2;
}

sub modulus_byte_length {
    my ($self) = @_;

    return length $self->N()->as_bytes();

    #return( ( length( $self->N()->as_hex() ) - 2 ) / 2 );
}

sub verify_RS256 {
    my ($self, $msg, $sig) = @_;

    return $self->_verify($msg, $sig, 'Digest::SHA', 'sha256', 'PKCS1_v1_5');
}

sub verify_RS384 {
    my ($self, $msg, $sig) = @_;

    return $self->_verify($msg, $sig, 'Digest::SHA', 'sha384', 'PKCS1_v1_5');
}

sub verify_RS512 {
    my ($self, $msg, $sig) = @_;

    return $self->_verify($msg, $sig, 'Digest::SHA', 'sha512', 'PKCS1_v1_5');
}

sub encrypt_raw {
    my ($self, $bytes) = @_;

    return Crypt::Perl::BigInt->from_bytes($bytes)->bmodpow($self->{'publicExponent'}, $self->{'modulus'})->as_bytes();
}

sub to_der {
    my ($self) = @_;

    return $self->_to_der($self->_ASN1_MACRO());
}

sub algorithm_identifier {
    my ($self) = @_;

    return {
        algorithm => OID_rsaEncryption(),
        parameters => Crypt::Perl::ASN1::NULL(),
    };
}

use constant OID_rsaEncryption => '1.2.840.113549.1.1.1';

sub _to_subject_public_der {
    my ($self) = @_;

    my $asn1 = $self->_asn1_find('SubjectPublicKeyInfo');

    return $asn1->encode( {
        algorithm => $self->algorithm_identifier(),
        subjectPublicKey => $self->_to_der('RSAPublicKey'),
    } );
}

sub get_struct_for_public_jwk {
    my ($self) = @_;

    require MIME::Base64;

    return {
        kty => 'RSA',
        n => MIME::Base64::encode_base64url($self->N()->as_bytes()),
        e => MIME::Base64::encode_base64url($self->E()->as_bytes()),
    }
}

#----------------------------------------------------------------------

sub _asn1_find {
    my ($self, $macro) = @_;

    require Crypt::Perl::ASN1;
    require Crypt::Perl::RSA::Template;
    my $asn1 = Crypt::Perl::ASN1->new()->prepare(
        Crypt::Perl::RSA::Template::get_template('INTEGER'),
    );

    return $asn1->find($macro);
}

sub _to_der {
    my ($self, $macro) = @_;

    return $self->_asn1_find($macro)->encode( { %$self } );
}

sub _verify {
    my ($self, $message, $signature, $hash_module, $hasher, $scheme) = @_;

    Module::Load::load($hash_module);

    my $digest = $hash_module->can($hasher)->($message);

    my $y = Crypt::Perl::BigInt->from_hex( unpack 'H*', $signature );

    #This modifies $y, but it doesn’t matter here.
    my $x = $y->bmodpow( $self->E(), $self->N() );

    #Math::BigInt will strip off the leading zero that PKCS1_v1_5 requires,
    #so let’s put it back first of all.
    my $octets = "\0" . $x->as_bytes();

    #printf "OCTETS - %v02x\n", $octets;

    if ($scheme eq 'PKCS1_v1_5') {
        my $key_bytes_length = $self->modulus_byte_length();
        if (length($octets) != $key_bytes_length) {
            my $err = sprintf( "Invalid PKCS1_v1_5 length: %d (should be %d)", length($octets), $key_bytes_length );
            die Crypt::Perl::X::create('Generic', $err);
        }

        require Crypt::Perl::RSA::PKCS1_v1_5;
        return $digest eq Crypt::Perl::RSA::PKCS1_v1_5::decode($octets, $hasher);
    }

    die Crypt::Perl::X::create('Generic', "Unknown signature scheme: “$scheme”");
}

1;
