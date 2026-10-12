package Dancer2::Session::Pg::Cipher::AESGCM;

use strict;
use warnings;

use Moo;
use Carp                qw( croak );
use Crypt::AuthEnc::GCM ();

our $VERSION = '0.002';

# The key length is the only thing that distinguishes the three, and it decides
# the stored id -- so these three numbers are as permanent as the ids are.
my %ID_FOR_KEY_BYTES = (
    16 => 1,
    24 => 2,
    32 => 3,
);

has key_bytes => ( is => 'ro', default => sub { 32 } );

# BELOW the attribute, not above it: the role requires key_bytes, and Role::Tiny
# checks the required list at the moment `with` runs -- before `has` has made the
# accessor. Moving this line up gives "missing key_bytes" at compile time.
with 'Dancer2::Session::Pg::Cipher';

sub BUILD {
    my ($self) = @_;
    croak sprintf '%s: key_bytes must be 16, 24 or 32 (got %s)', ref $self,
      ( defined $self->key_bytes ? $self->key_bytes : 'undef' )
      if !defined $self->key_bytes || !exists $ID_FOR_KEY_BYTES{ $self->key_bytes };
    return;
}

sub cipher_id   { my ($self) = @_; return $ID_FOR_KEY_BYTES{ $self->key_bytes } }
sub cipher_name { my ($self) = @_; return sprintf 'AES-%d-GCM', 8 * $self->key_bytes }
sub iv_bytes    { return 12 }
sub tag_bytes   { return 16 }

sub seal {
    my ( $self, $key, $iv, $plaintext, $aad ) = @_;
    return Crypt::AuthEnc::GCM::gcm_encrypt_authenticate( 'AES', $key, $iv, $aad, $plaintext );
}

sub unseal {    ## no critic (Subroutines::ProhibitManyArgs) -- six is the AEAD contract in Dancer2::Session::Pg::Cipher
    my ( $self, $key, $iv, $ciphertext, $tag, $aad ) = @_;
    return Crypt::AuthEnc::GCM::gcm_decrypt_verify( 'AES', $key, $iv, $aad, $ciphertext, $tag );
}

1;

__END__

=encoding utf8

=for stopwords AEAD AES GCM AESGCM ChaCha ChaCha20 Poly1305 nonce plaintext Mikko Koivunalho

=head1 NAME

Dancer2::Session::Pg::Cipher::AESGCM - AES-GCM for Dancer2::Session::Pg

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Dancer2::Session::Pg ();

    my %slot_by_name = (
        0 => { key => $ENV{'SESSION_KEY_0'}, alg => 'AES-256-GCM', active => 1 },
    );

    # the same thing spelled out, which is only needed to pass arguments
    my %slot_by_class = (
        0 => {
            key    => $ENV{'SESSION_KEY_0'},
            alg    => [ 'Dancer2::Session::Pg::Cipher::AESGCM', key_bytes => 32 ],
            active => 1,
        },
    );

=head1 DESCRIPTION

AES in Galois/Counter Mode, from L<CryptX>, in all three key lengths. The
default cipher of L<Dancer2::Session::Pg>: AES-NI makes it the fastest option on
essentially every server CPU in use, it is the most widely reviewed choice, and
it is the one most likely to be acceptable to whoever audits you.

Does L<Dancer2::Session::Pg::Cipher>. A 96-bit nonce and a 128-bit tag, which
is the usual pairing for GCM and the one every other implementation will expect.

=head1 ATTRIBUTES

=head2 key_bytes

C<16>, C<24> or C<32>, defaulting to C<32>. Anything else croaks at
construction. The value selects the stored cipher id, so it is not a free
parameter:

    key_bytes   cipher_name     cipher_id
    16          AES-128-GCM     1
    24          AES-192-GCM     2
    32          AES-256-GCM     3

=head1 METHODS

See L<Dancer2::Session::Pg::Cipher> for the contract. C<iv_bytes> is 12 and
C<tag_bytes> is 16 for every key length.

=head1 SEE ALSO

L<Dancer2::Session::Pg>, L<Dancer2::Session::Pg::Cipher>, L<CryptX>

=begin Pod::Coverage

BUILD
cipher_id
cipher_name
iv_bytes
tag_bytes
seal
unseal

=end Pod::Coverage

=head1 AUTHOR

Mikko Koivunalho <mikko.koivunalho@iki.fi>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
