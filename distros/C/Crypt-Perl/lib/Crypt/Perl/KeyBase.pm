package Crypt::Perl::KeyBase;

use strict;
use warnings;

use Crypt::Perl::X ();

sub get_jwk_thumbprint {
    my ($self, $hash_alg) = @_;

    die Crypt::Perl::X::create('Generic', 'Need a hashing algorithm!') if !length $hash_alg;

    require Digest::SHA;
    my $hash_cr = ($hash_alg =~ m<\Asha[0-9]+\z>) && Digest::SHA->can($hash_alg) or do {
        die Crypt::Perl::X::create('UnknownHash', $hash_alg);
    };

    my $jwk = $self->get_struct_for_public_jwk();

    my $json = sprintf(
        '{' . join(',', map { qq{"$_":"%s"} } $self->_JWK_THUMBPRINT_JSON_ORDER()) . '}',
        @{$jwk}{ $self->_JWK_THUMBPRINT_JSON_ORDER() },
    );

    require MIME::Base64;

    return MIME::Base64::encode_base64url( $hash_cr->($json) );
}

1;
