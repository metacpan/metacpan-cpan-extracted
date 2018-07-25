package Crypt::Perl::Ed25519::KeyBase;

use strict;
use warnings;

use Crypt::Perl::Ed25519::Math;
use Crypt::Perl::X;

use Digest::SHA ();

use parent qw( Crypt::Perl::KeyBase );

use constant {
    SIGN_BYTE_LENGTH => 64,
    OID_Ed25519 => '1.3.101.112',
};

use constant _ASN1_BASE => q<
    -- cf. RFC 3280 4.1.1.2
    -- XXX COPIED FROM RSA TEMPLATE MODULE
    AlgorithmIdentifier  ::=  SEQUENCE  {
        algorithm               OBJECT IDENTIFIER,
        parameters              ANY DEFINED BY algorithm OPTIONAL
    }
>;

use constant _JWK_THUMBPRINT_JSON_ORDER => qw( crv kty x );

sub to_der {
    my ($self) = @_;

    require Crypt::Perl::ASN1;
    my $asn1 = Crypt::Perl::ASN1->new()->prepare(
        _ASN1_BASE() . $self->_ASN1()
    )->find('FG_Key');

    return $asn1->encode( {
        version => 0,
        algorithmIdentifier => {
            algorithm => OID_Ed25519(),
        },
        $self->_to_der_args(),
    } );
}

# TODO: refactor; duplicated w/ RSA
sub to_pem {
    my ($self) = @_;

    require Crypt::Format;
    return Crypt::Format::der2pem( $self->to_der(), $self->_PEM_HEADER() );
}

sub get_public {
    my ($self) = @_;

    return $self->{'_public'};
}

sub get_struct_for_public_jwk {
    my ($self) = @_;

    require MIME::Base64;

    return {
        kty => 'OKP',
        crv => 'Ed25519',
        x => MIME::Base64::encode_base64url($self->{'_public'}),
    }
}

sub verify {
    my ($self, $msg, $sig) = @_;

    if (SIGN_BYTE_LENGTH() != length $sig) {
        die Crypt::Perl::X::create('Generic', sprintf('Invalid length (%d) of Ed25519 signature: %v.02x', length($sig), $sig));
    }

    my $public_ar = $self->{'_public_ar'};

    my $sig_ar = [ unpack 'C*', $sig ];

    my @sm = ( @$sig_ar, unpack( 'C*', $msg ) );
    my @m = (0) x @sm;

    @m = @sm;

    @m[ 32 .. 63 ] = @{$public_ar};

    my @p = map { [ Crypt::Perl::Ed25519::Math::gf0() ] } 1 .. 4;
    my @q = map { [ Crypt::Perl::Ed25519::Math::gf0() ] } 1 .. 4;

    if ( Crypt::Perl::Ed25519::Math::unpackneg( \@q, $public_ar ) ) {
        return !1;
    }

    my @h = unpack 'C*', Digest::SHA::sha512( pack 'C*', @m );
    Crypt::Perl::Ed25519::Math::reduce(\@h);

    Crypt::Perl::Ed25519::Math::scalarmult(\@p, \@q, \@h);

    my @latter_sm = @sm[32 .. $#sm];
    Crypt::Perl::Ed25519::Math::scalarbase( \@q, \@latter_sm );
    @sm[32 .. $#sm] = @latter_sm;

    Crypt::Perl::Ed25519::Math::add( \@p, \@q );
    my $t_ar = Crypt::Perl::Ed25519::Math::pack(\@p);

    if( Crypt::Perl::Ed25519::Math::crypto_verify_32(\@sm, 0, $t_ar, 0)) {
        return !1;
    }

    my $n = @sm - SIGN_BYTE_LENGTH;

    return $n >= 0;
}

sub _verify_binary_key_part {
    if (32 != length $_[1]) {
        die Crypt::Perl::X::create('Generic', sprintf('Invalid length (%d) of Ed25519 key piece: %v.02x', length($_[1]), $_[1]));
    }

    return;
}

1;
