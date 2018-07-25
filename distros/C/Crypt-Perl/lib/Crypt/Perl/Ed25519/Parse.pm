package Crypt::Perl::Ed25519::Parse;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::Ed25519::Parse

=head1 SYNOPSIS

    # These accept either DER or PEM.
    my $prkey = Crypt::Perl::Ed25519::Parse::private($buffer);
    my $pbkey = Crypt::Perl::Ed25519::Parse::public($buffer);

    # This accepts a structure, not raw JSON.
    my $key = Crypt::Perl::Ed25519::Parse::jwk($jwk_hr);

=head1 DESCRIPTION

See L<Crypt::Perl::Ed25519::PrivateKey> and L<Crypt::Perl::Ed25519::PublicKey>
for descriptions of the interfaces that this module returns.

=cut

use Crypt::Perl::PKCS8 ();
use Crypt::Perl::ToDER ();

# DER or PEM

sub private {
    my $pem_or_der = shift;

    Crypt::Perl::ToDER::ensure_der($pem_or_der);

    my $struct = Crypt::Perl::PKCS8::parse_private($pem_or_der);

    require Crypt::Perl::Ed25519::PrivateKey;

    _check_oid($struct->{'privateKeyAlgorithm'}, 'Crypt::Perl::Ed25519::PrivateKey');

    substr( $struct->{'privateKey'}, 0, 2 ) = q<>;

    return Crypt::Perl::Ed25519::PrivateKey->new( $struct->{'privateKey'} );
}

sub public {
    my $pem_or_der = shift;

    Crypt::Perl::ToDER::ensure_der($pem_or_der);

    my $struct = Crypt::Perl::PKCS8::parse_public($pem_or_der);

    require Crypt::Perl::Ed25519::PublicKey;

    _check_oid($struct->{'algorithm'}, 'Crypt::Perl::Ed25519::PublicKey');

    return Crypt::Perl::Ed25519::PublicKey->new( $struct->{'subjectPublicKey'}[0] );
}

# https://tools.ietf.org/html/rfc8037
sub jwk {
    my ($struct_hr) = @_;

    require MIME::Base64;

    my $x = $struct_hr->{'x'} && MIME::Base64::decode_base64url($struct_hr->{'x'});

    if ($struct_hr->{'d'}) {
        my $d = MIME::Base64::decode_base64url($struct_hr->{'d'}) or do {
            die "Neither “x” nor “d”!";
        };

        require Crypt::Perl::Ed25519::PrivateKey;
        return Crypt::Perl::Ed25519::PrivateKey->new( $d, $x );
    }

    die "Neither “x” nor “d”!" if !$x;

    require Crypt::Perl::Ed25519::PublicKey;
    return Crypt::Perl::Ed25519::PublicKey->new( $x );
}

sub _check_oid {
    my ($substruct, $class) = @_;

    if ( $substruct->{'algorithm'} ne $class->OID_Ed25519() ) {
        die "OID ($substruct->{'algorithm'}) is not Ed25519!\n";
    }

    return;
}

1;
