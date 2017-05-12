package Authen::HTTP::Signature::Method::HMAC;

use 5.010;
use warnings;
use strict;

use Moo;
use Digest::SHA qw(hmac_sha1_base64 hmac_sha256_base64 hmac_sha512_base64);
use Carp qw(confess);

=head1 NAME

Authen::HTTP::Signature::Method::HMAC - Compute digest using a symmetric key

=cut

our $VERSION = '0.03';

=head1 PURPOSE

This class uses a symmetric key to compute a HTTP signature digest. It implements the
HMAC-SHA{1, 256, 512} algorithms.

=head1 ATTRIBUTES

These are Perlish mutators; pass a value to set it, pass no value to get the current value.

=over

=item key

Key material. Read-only. Required.

=back

=cut

has 'key' => (
    is => 'ro',
    required => 1,
);

=over

=item data

The data to be signed. Read-only. Required.

=back

=cut

has 'data' => (
    is => 'ro',
    required => 1,
);

=over

=item hash

The algorithm to generate the digest. Read-only. Required.

=back

=cut

has 'hash' => (
    is => 'ro',
    required => 1,
);

=head1 METHODS

=cut

sub _pad_base64 {
    my $self = shift;
    my $b64_str = shift;

    my $n = length($b64_str) % 4;

    if ( $n ) {
        $b64_str .= '=' x (4-$n);
    }

    return $b64_str;
}

sub _get_digest {
    my $self = shift;
    my $algo = shift;
    my $data = shift;
    my $key = shift;

    my $digest;
    if ( $algo =~ /sha1/ ) {
        $digest = hmac_sha1_base64($data, $key);
    }
    elsif ( $algo =~ /sha256/ ) {
        $digest = hmac_sha256_base64($data, $key);
    }
    elsif ( $algo =~ /sha512/ ) {
        $digest = hmac_sha512_base64($data, $key);
    }

    confess "I couldn't get a $algo digest\n" unless defined $digest && length $digest;

    return $digest;
}

=over

=item sign()

Signs C<data> with C<key> using C<hash>.

Returns a Base 64 encoded digest.

=back

=cut

sub sign {
    my $self = shift;

    return $self->_generate_signature();
}

sub _generate_signature {
    my $self = shift;

    return $self->_pad_base64( 
        $self->_get_digest(
            $self->hash,
            $self->data,
            $self->key
        )
    );
}

=over

=item verify()

Compares the given signature to a computed one.  Returns true if they are the same. False otherwise.

=back

=cut

sub verify {
    my $self = shift;
    my $candidate = shift;

    confess "How can I validate anything without a signature?" unless $candidate;

    return $self->_generate_signature() eq $candidate;
}

=head1 SEE ALSO

L<Authen::HTTP::Signature>

=cut

1;
