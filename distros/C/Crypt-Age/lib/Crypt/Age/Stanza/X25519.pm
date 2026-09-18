package Crypt::Age::Stanza::X25519;
# ABSTRACT: X25519 recipient stanza for age encryption
our $VERSION = '0.004';
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


# c2sp.org/age, X25519 recipient type: "The identity implementation MUST ignore
# any stanza that does not have X25519 as the first argument, and MUST otherwise
# reject any stanza that has more or less than two arguments, or where the second
# argument is not a canonical base64 encoding of a 32-byte value. It MUST check
# that the body length is exactly 32 bytes before attempting to decrypt it, to
# mitigate partitioning oracle attacks."
#
# The spec counts the type as the first of those two arguments; our args
# attribute holds everything after the type, so "exactly two" is exactly one
# here.
#
# The checks live in the constructor rather than in Header::parse or in unwrap:
#
#   * Header::parse already dispatches on the type string to choose this class,
#     so validating here fires while the header is being parsed. The header is
#     rejected before any identity is consulted, which is the header failure the
#     spec asks for -- not the "this identity does not match, try the next
#     stanza" that unwrap returning undef means.
#   * Class dispatch scopes the rules exactly right. A stanza of an unrecognized
#     type is built as a plain Crypt::Age::Stanza and MUST be ignored rather
#     than rejected, so it never reaches this code and needs no exemption.
#   * body is 'ro', so the 32-byte invariant holds for the object's lifetime.
#     That is what keeps the eval in unwrap honest: a wrong-length body can no
#     longer be constructed, so the only croak that eval still swallows is the
#     AEAD authentication failure, which genuinely means "wrong identity".
#
# The base64 canonicality rules -- padding, alphabet, impossible lengths,
# non-canonical trailing bits -- are already enforced by
# Stanza::decode_base64_no_padding and are deliberately not repeated here; its
# croak propagates from the call below. Every message names the reason and never
# the value: args and body are key material.

sub BUILD {
    my ($self) = @_;

    croak "Invalid X25519 stanza: expected exactly one argument after the type"
        unless @{$self->args} == 1;

    my $ephemeral_share = Crypt::Age::Stanza::decode_base64_no_padding($self->args->[0]);
    croak "Invalid X25519 stanza: argument does not decode to a 32-byte value"
        unless length($ephemeral_share) == 32;

    croak "Invalid X25519 stanza: body is not exactly 32 bytes"
        unless length($self->body) == 32;

    return;
}


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


sub identity_keys {
    my ($self, $identity_secret_key) = @_;

    # Decode identity secret key (Bech32 -> raw bytes)
    my $identity_private = Crypt::Age::Keys->decode_secret_key($identity_secret_key);

    # Get recipient's public key from identity
    my $pk = Crypt::PK::X25519->new;
    $pk->import_key_raw($identity_private, 'private');

    return {
        private => $identity_private,
        public  => $pk->export_key_raw('public'),
    };
}


sub unwrap {
    my ($self, $identity_secret_key, $identity_keys) = @_;

    # Deriving the identity's public key costs a scalar multiplication, and
    # neither it nor the Bech32 decode depends on this stanza -- so the caller
    # is allowed to do it once per identity and hand the result down, which is
    # what Header::unwrap_file_key does for a header with many stanzas
    # (CVE-2026-85783). Falling back to deriving it here keeps the documented
    # one-argument call in the SYNOPSIS working, and keeps an invalid Bech32
    # identity failing at exactly the point it always did: on the first X25519
    # stanza the identity is tried against, not earlier.
    $identity_keys //= $self->identity_keys($identity_secret_key);
    my $identity_private = $identity_keys->{private};
    my $recipient_public = $identity_keys->{public};

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

    # Unwrap file key. This eval must swallow one thing only: the AEAD
    # authentication failure that means "this identity is not the one this
    # stanza was written for", which the caller reads as undef and answers by
    # trying the next identity or stanza. Everything structural is already a
    # header failure by the time we get here -- BUILD guarantees a 32-byte body,
    # so unwrap_file_key's own length croak is unreachable, and the wrap key is
    # a fixed-length HKDF output. Widening what is inside this eval would turn a
    # malformed header back into a silent "no match".
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

version 0.004

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

This is an internal module used by L<Crypt::Age>.

=head2 ephemeral_public

The ephemeral X25519 public key used for this stanza (raw bytes).

Only set on the encrypt path: L</wrap> generates it and passes it to the
constructor. A stanza built by L<Crypt::Age::Header/parse_from_fh> on the
decrypt path leaves this C<undef> -- the same key is present there too, but
base64-encoded in the inherited C<args> attribute (C<args-E<gt>[0]>), which is
what L</unwrap> decodes for itself rather than reading this attribute.

=head2 BUILD

Validates the stanza at construction time. Not called directly; it runs from
C<new>, and therefore from L</wrap> and from L<Crypt::Age::Header/parse>, which
builds this class for every stanza whose type is C<X25519>.

The age format requires an identity implementation to reject -- as a header
failure, not as an identity that merely does not match -- an C<X25519> stanza
that

=over 4

=item * does not carry exactly one argument after the type

=item * whose argument is not the canonical unpadded base64 encoding of a
32-byte value

=item * whose body is not exactly 32 bytes, which mitigates partitioning oracle
attacks by refusing to attempt decryption at all

=back

Dies on any of these. The messages give the reason and never the offending
value, which is key material. Stanzas of other types are not affected: they are
built as plain L<Crypt::Age::Stanza> objects and are ignored rather than
rejected, as the format requires.

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

=head2 identity_keys

    my $keys = Crypt::Age::Stanza::X25519->identity_keys($identity_secret_key);

Turns a Bech32-encoded identity into the two raw values L</unwrap> needs from
it: a HashRef with C<private>, the 32 secret bytes, and C<public>, the identity's
own X25519 public key -- which is the recipient key the wrapping key is salted
with, so it is named for that role inside L</unwrap>.

Neither value depends on any stanza, and deriving C<public> is itself a scalar
multiplication, so this exists to be called once per identity rather than once
per stanza; see L</unwrap> and L<Crypt::Age::Header/unwrap_file_key>. Uses no
part of the invocant, so it reads as a class method.

Dies exactly as L<Crypt::Age::Keys/decode_secret_key> does, and quotes no part
of the identity.

=head2 unwrap

    my $file_key = $stanza->unwrap($identity_secret_key);
    my $file_key = $stanza->unwrap($identity_secret_key, $identity_keys);

Attempts to unwrap the file key using an identity.

Parameters:

=over 4

=item * C<$identity_secret_key> - Bech32-encoded secret key (C<AGE-SECRET-KEY-1...>)

=item * C<$identity_keys> - Optional. What L</identity_keys> returned for that
same identity. Passing it skips the Bech32 decode and the scalar multiplication
that recover the identity's raw keys, neither of which depends on this stanza.
When it is given, C<$identity_secret_key> is not looked at

=back

Performs key exchange with the ephemeral public key from the stanza, derives
the wrapping key, and attempts to unwrap the file key.

A caller trying one identity against many stanzas should derive the identity's
keys once and pass them in -- that is why the second parameter exists, and
L<Crypt::Age::Header/unwrap_file_key> does it. Omitting it derives them here
instead, so the one-argument call above is unchanged, and an identity that is
not valid Bech32 still dies at the first stanza it is tried against rather
than earlier.

Returns the 16-byte file key on success, or C<undef> when the AEAD
authentication fails, which means this identity is not the one the stanza was
written for. C<undef> is the only "no match" answer: a structurally invalid
stanza cannot be constructed in the first place (see L</BUILD>), and a
low-order-point ephemeral share dies rather than returning C<undef>.

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
