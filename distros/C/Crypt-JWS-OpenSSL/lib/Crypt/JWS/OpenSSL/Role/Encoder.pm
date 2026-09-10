package Crypt::JWS::OpenSSL::Role::Encoder;
$Crypt::JWS::OpenSSL::Role::Encoder::VERSION = '0.005';
use Moo::Role;
use MIME::Base64 ();
use JSON::MaybeXS 1.002002 ();
use Carp qw( croak );
use version 0.78;

has 'JSON' => ( is => 'ro', default => sub { JSON::MaybeXS->new->utf8(1) } );

sub parse_params {
    my $self = shift;
    my %params;
    if ( @_ % 2 ) {
        if ( ref $_[0] eq 'HASH' ) {
            %params = %{ shift() };
        } else {
            croak('Expecting a HASH ref or a list of key-value pairs');
        }
    }
    else {
        %params = @_;
    }
    return ( $self, \%params );
}

sub encode_jwt_segment {
    my($self, $ref) = @_;
    my $bytes = $self->JSON->encode($ref);
    my $base64 = MIME::Base64::encode_base64($bytes, '');
    $base64 =~ s!=+\z!!;
    $base64 =~ tr[+/][-_];
    return $base64;
}

sub decode_jwt_segment {
    my($self, $base64) = @_;
    $base64 =~ tr[-_][+/];
    $base64 .= '=' while length($base64) % 4;
    my $json = MIME::Base64::decode_base64($base64);
    return $self->JSON->decode($json);
}

sub encode_jwt_signature {
    my($self, $bytes) = @_;
    return $self->encode_base64_url($bytes);
}

sub decode_jwt_signature {
    my($self, $base64) = @_;
    return $self->decode_base64_url($base64);
}

sub encode_jwk_element {
    my($self, $bytes) = @_;
    return $self->encode_base64_url($bytes);
}

sub decode_jwk_element {
    my($self, $base64) = @_;
    return $self->decode_base64_url($base64);
}

sub encode_base64_url {
    my($self, $bytes) = @_;
    my $base64 = $self->encode_base64($bytes);
    $base64 =~ s!=+\z!!;
    $base64 =~ tr[+/][-_];
    return $base64;
}

sub encode_base64 {
    my($self, $bytes) = @_;
    return MIME::Base64::encode_base64($bytes, '');
}

sub decode_base64_url {
    my($self, $base64) = @_;
    $base64 =~ tr[-_][+/];
    $base64 .= '=' while length($base64) % 4;
    return $self->decode_base64($base64);
}

sub decode_base64 {
    my($self, $base64) = @_;
    return MIME::Base64::decode_base64($base64);
}

sub encode_rsa_private_key_pem {
    my($self, $bytes) = @_;
    return $self->_encode_pem(\$bytes, 'PRIVATE KEY');
}

sub encode_rsa_public_key_pem {
    my($self, $bytes) = @_;
    return $self->_encode_pem(\$bytes, 'PUBLIC KEY');
}

sub encode_ecc_private_key_pem {
    my($self, $bytes) = @_;
    return $self->_encode_pem(\$bytes, 'EC PRIVATE KEY');
}

sub encode_ecc_public_key_pem {
    my($self, $bytes) = @_;
    return $self->_encode_pem(\$bytes, 'PUBLIC KEY');
}

sub _encode_pem {
    my ($self, $bytes_ref, $type) = @_;
    my $pem = $self->encode_base64($$bytes_ref);
    $pem = join( qq(\n), $pem =~ m!(.{1,64})!g, '' );
    substr( $pem, 0, 0, "-----BEGIN $type-----\n" );
    substr( $pem, length($pem), 0, "-----END $type-----\n" );
    return $pem;
}

sub decode_pem {
    my ($self, $pem) = @_;
    $pem =~ s!-----(BEGIN|END)[^-]*-----!!g;
    return $self->decode_base64($pem);
}

sub numify_version {
    my ($self, $vstring) = @_;
    no warnings;
    my $ver = version->parse($vstring)->numify;
    return $ver;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Role::Encoder - Provides encoding and decoding methods.

Composed into

=over

=item

L<Crypt::JWS::OpenSSL>

=item

L<Crypt::JWS::OpenSSL::Util::JWK>

=item

L<Crypt::JWS::OpenSSL::Util::PEM>

=item

L<Crypt::JWS::OpenSSL::Algorithm::ECC>

=item

L<Crypt::JWS::OpenSSL::Algorithm::RSA>

=item

L<Crypt::JWS::OpenSSL::Algorithm::HMAC>

=back

=head1 VERSION

version 0.005

=head1 METHODS

=head2 encode_jwt_segment

Accepts a hash refrence. Encodes the hash reference as JSON  and
returns the Base64 URL encoded JSON.

=head2 decode_jwt_segment

Accepts a Base64 URL encoded JSON string. Decodes the input and returns
the decoded JSON as a hash reference.

=head2 encode_jwt_signature

Accepts raw bytes and returns the Base64 URL encoded result.

=head2 decode_jwt_signature

Accepts a Base64 URL encoded string and returns the raw decoded bytes.

=head2 encode_jwk_element

Accepts raw bytes and returns the Base64 URL encoded result.

=head2 decode_jwk_element

Accepts a Base64 URL encoded string and returns the raw decoded bytes.

=head2 encode_rsa_private_key_pem

Accepts a der encoded RSA private key and returns the pem encoded result.

=head2 encode_rsa_public_key_pem

Accepts a der encoded RSA public key and returns the pem encoded result.

=head2 encode_ecc_private_key_pem

Accepts a der encoded EC private key and returns the pem encoded result.

=head2 encode_ecc_public_key_pem

Accepts a der encoded EC public key and returns the pem encoded result.

=head2 decode_pem

Decodes a pem format key and returns the der result.

=head2 encode_base64_url

Convenience method

=head2 decode_base64_url

Convenience method

=head2 encode_base64

Convenience method

=head2 decode_base64

Convenience method

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut