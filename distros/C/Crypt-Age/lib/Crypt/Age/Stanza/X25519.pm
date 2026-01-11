package Crypt::Age::Stanza::X25519;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: X25519 recipient stanza for age encryption

use Moo;
use Carp qw(croak);
use Crypt::Age::Keys;
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use namespace::clean;


extends 'Crypt::Age::Stanza';

has '+type' => (
    default => 'X25519',
);

has ephemeral_public => (
    is => 'ro',
);


sub wrap {
    my ($class, $file_key, $recipient_public_key) = @_;

    # Decode recipient public key (Bech32 -> raw bytes)
    my $recipient_public = Crypt::Age::Keys->decode_public_key($recipient_public_key);

    # Generate ephemeral keypair
    my ($ephemeral_public, $ephemeral_private) =
        Crypt::Age::Primitives->x25519_generate_keypair;

    # Compute shared secret
    my $shared_secret = Crypt::Age::Primitives->x25519_shared_secret(
        $ephemeral_private,
        $recipient_public
    );

    # Derive wrap key
    my $wrap_key = Crypt::Age::Primitives->derive_wrap_key(
        $shared_secret,
        $ephemeral_public,
        $recipient_public
    );

    # Wrap file key
    my $wrapped_key = Crypt::Age::Primitives->wrap_file_key($wrap_key, $file_key);

    # Create stanza
    return $class->new(
        args             => [Crypt::Age::Stanza::encode_base64_no_padding($ephemeral_public)],
        body             => $wrapped_key,
        ephemeral_public => $ephemeral_public,
    );
}


sub unwrap {
    my ($self, $identity_secret_key) = @_;

    # Decode identity secret key (Bech32 -> raw bytes)
    my $identity_private = Crypt::Age::Keys->decode_secret_key($identity_secret_key);

    # Get recipient's public key from identity
    my $pk = Crypt::PK::X25519->new;
    $pk->import_key_raw($identity_private, 'private');
    my $recipient_public = $pk->export_key_raw('public');

    # Decode ephemeral public key from stanza args
    my $ephemeral_public = Crypt::Age::Stanza::decode_base64_no_padding($self->args->[0]);

    # Compute shared secret
    my $shared_secret = Crypt::Age::Primitives->x25519_shared_secret(
        $identity_private,
        $ephemeral_public
    );

    # Derive wrap key
    my $wrap_key = Crypt::Age::Primitives->derive_wrap_key(
        $shared_secret,
        $ephemeral_public,
        $recipient_public
    );

    # Unwrap file key
    my $file_key = eval {
        Crypt::Age::Primitives->unwrap_file_key($wrap_key, $self->body);
    };

    return $file_key;  # Returns undef if unwrap failed
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age::Stanza::X25519 - X25519 recipient stanza for age encryption

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Crypt::Age::Stanza::X25519;

    # Create stanza by wrapping file key for a recipient
    my $stanza = Crypt::Age::Stanza::X25519->wrap($file_key, $recipient_public_key);

    # Unwrap file key using identity
    my $file_key = $stanza->unwrap($identity_secret_key);

=head1 DESCRIPTION

This module implements X25519 recipient stanzas for age encryption.

X25519 stanzas use Curve25519 Diffie-Hellman key exchange to derive a shared
secret, which is then used to wrap the file key with ChaCha20-Poly1305.

The stanza format is:

    -> X25519 <base64-ephemeral-public-key>
    <base64-wrapped-file-key>

The ephemeral public key is generated randomly for each encryption operation.
The recipient uses their identity (secret key) to compute the same shared
secret and unwrap the file key.

This is the primary recipient type for age encryption.

=head2 ephemeral_public

The ephemeral X25519 public key used for this stanza (raw bytes).

Generated randomly during wrapping.

=head2 wrap

    my $stanza = Crypt::Age::Stanza::X25519->wrap($file_key, $recipient_public_key);

Wraps a file key for a recipient.

Parameters:

=over 4

=item * C<$file_key> - The 16-byte file key to wrap

=item * C<$recipient_public_key> - Bech32-encoded public key (C<age1...>)

=back

Generates an ephemeral X25519 keypair, performs key exchange with the
recipient's public key, derives a wrapping key, and wraps the file key.

Returns a L<Crypt::Age::Stanza::X25519> object.

=head2 unwrap

    my $file_key = $stanza->unwrap($identity_secret_key);

Attempts to unwrap the file key using an identity.

Parameters:

=over 4

=item * C<$identity_secret_key> - Bech32-encoded secret key (C<AGE-SECRET-KEY-1...>)

=back

Performs key exchange with the ephemeral public key from the stanza, derives
the wrapping key, and attempts to unwrap the file key.

Returns the 16-byte file key on success, or C<undef> if unwrapping fails
(wrong identity or corrupted data).

=head1 SEE ALSO

=over 4

=item * L<Crypt::Age> - Main age encryption module

=item * L<Crypt::Age::Stanza> - Base stanza class

=item * L<Crypt::Age::Primitives> - Low-level cryptographic operations

=item * L<Crypt::Age::Keys> - Key encoding/decoding

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-crypt-age/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
