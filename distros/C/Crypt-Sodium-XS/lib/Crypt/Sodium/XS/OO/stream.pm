package Crypt::Sodium::XS::OO::stream;
use strict;
use warnings;

use Crypt::Sodium::XS::stream;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_NONCEBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::stream::stream_PRIMITIVE,
    keygen => \&Crypt::Sodium::XS::stream::stream_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream,
    xor => \&Crypt::Sodium::XS::stream::stream_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_xor_ic,
  },
  chacha20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_chacha20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_NONCEBYTES,
    PRIMITIVE => sub { 'chacha20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_chacha20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_chacha20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_chacha20,
    xor => \&Crypt::Sodium::XS::stream::stream_chacha20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_chacha20_xor_ic,
  },
  chacha20_ietf => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_NONCEBYTES,
    PRIMITIVE => sub { 'chacha20_ietf' },
    keygen => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf,
    xor => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_xor_ic,
  },
  salsa20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_salsa20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_salsa20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_salsa20_NONCEBYTES,
    PRIMITIVE => sub { 'salsa20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_salsa20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_salsa20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_salsa20,
    xor => \&Crypt::Sodium::XS::stream::stream_salsa20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_salsa20_xor_ic,
  },
  salsa2012 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_salsa2012_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_salsa2012_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_salsa2012_NONCEBYTES,
    PRIMITIVE => sub { 'salsa2012' },
    keygen => \&Crypt::Sodium::XS::stream::stream_salsa2012_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_salsa2012_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_salsa2012,
    xor => \&Crypt::Sodium::XS::stream::stream_salsa2012_xor,
    xor_ic => sub { die "xor_ic not supported for salsa2012 primitive" },
  },
  xchacha20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_xchacha20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_xchacha20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_xchacha20_NONCEBYTES,
    PRIMITIVE => sub { 'xchacha20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_xchacha20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_xchacha20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_xchacha20,
    xor => \&Crypt::Sodium::XS::stream::stream_xchacha20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_xchacha20_xor_ic,
  },
  xsalsa20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_xsalsa20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_xsalsa20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_xsalsa20_NONCEBYTES,
    PRIMITIVE => sub { 'xsalsa20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_xsalsa20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_xsalsa20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_xsalsa20,
    xor => \&Crypt::Sodium::XS::stream::stream_xsalsa20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_xsalsa20_xor_ic,
  },
);

sub primitives { keys %methods }

sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub MESSAGEBYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{MESSAGEBYTES_MAX}; }
sub NONCEBYTES { my $self = shift; goto $methods{$self->{primitive}}->{NONCEBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub nonce { my $self = shift; goto $methods{$self->{primitive}}->{nonce}; }
sub stream { my $self = shift; goto $methods{$self->{primitive}}->{stream}; }
sub xor { my $self = shift; goto $methods{$self->{primitive}}->{xor}; }
sub xor_ic { my $self = shift; goto $methods{$self->{primitive}}->{xor_ic}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::stream - Stream ciphers

=head1 SYNOPSIS

  use Crypt::Sodium::XS::OO::stream;
  my $stream = Crypt::Sodium::XS::OO::stream->new;
  # or use the shortcut
  # use Crypt::Sodium::XS;
  # my $stream = Crypt::Sodium::XS->stream;

=head1 DESCRIPTION

These functions are stream ciphers. They do not provide authenticated
encryption. They can be used to generate pseudo-random data from a key, or as
building blocks for implementing custom constructions, but they are not
alternatives to L<Crypt::Sodium::XS::OO::secretbox>.

=head1 CONSTRUCTOR

=head2 new

  my $stream = Crypt::Sodium::XS::OO::stream->new;
  my $stream = Crypt::Sodium::XS::OO::stream->new(primitive => 'xchacha20');
  my $stream = Crypt::Sodium::XS->stream;

Returns a new secretstream object for the given primitive. If not given, the
default primitive is C<default>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $stream->primitive;
  $stream->primitive('xchacha20');

Gets or sets the primitive used for all operations by this object. Note this
can be C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = Crypt::Sodium::XS::OO::stream->primitives;
  my @primitives = $stream->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $stream->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 keygen

  my $key = $stream->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of L</KEYBYTES> bytes.

=head2 nonce

  my $nonce = $stream->nonce($base);

C<$base> is optional. It must be less than or equal to L</NONCEBYTES> bytes. If
not provided, the nonce will be random.

Returns a nonce of L</NONCEBYTES> bytes.

=head2 stream

  my $stream_data = $stream->stream($out_size, $nonce, $key);

C<$out_size> is the desired size, in bytes, of stream data output.

C<$nonce> is the nonce used to encrypt the stream data. It must be
L</NONCEBYTES> bytes.

C<$key> is the secret key used to encrypt the stream data. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns C<$out_size> bytes of stream data.

=head2 xor

  my $outdata = $stream->xor($indata, $nonce, $key, $flags);

C<$indata> is the data to xor. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to xor the data. It must be L</NONCEBYTES> bytes.

C<$key> is the secret key used to xor the data. It must be L</KEYBYTES> bytes.
It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. If provided, the returned data will be a
L<Crypt::Sodium::XS::MemVault>, created with the given flags.

Returns the xor result. May be a L<Crypt::Sodium::XS::MemVault>; see C<$flags>
above.

When using this method to decrypt data, C<$flags> should be passed (even if 0
or undef) to ensure the decrypted data is protected with a
L<Crypt::Sodium::XS::MemVault>.

=head2 xor_ic

  my $outdata
    = $stream->xor_ic($indata, $nonce, $internal_counter, $key, $flags);

B<Note>: xor_ic is not supported with the C<salsa2012> primitive.

C<$indata> is the data to xor. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to xor the data. It must be L</NONCEBYTES> bytes.

C<$internal_counter> is the initial value of the block counter.

C<$key> is the secret key used to xor the data. It must be L</KEYBYTES> bytes.
It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. If provided, the returned data will be a
L<Crypt::Sodium::XS::MemVault>, created with the given flags.

Returns the xor result. May be a L<Crypt::Sodium::XS::MemVault>; see C<$flags>
above.

L</xor_ic> is similar to L</xor> but adds the ability to set the initial value
of the block counter (C<$internal_counter>) to a non-zero value. This permits
direct access to any block without having to compute the previous ones.

When using this method to decrypt data, C<$flags> should be passed (even if 0
or undef) to ensure the decrypted data is protected with a
L<Crypt::Sodium::XS::MemVault>.

=head2 KEYBYTES

  my $key_size = $stream->KEYBYTES;

Returns the size, in bytes, of a secret key.

=head2 MESSAGEBYTES_MAX

  my $plaintext_max_size = $stream->MESSAGEBYTES_MAX;

Returns the size, in bytes, of the maximum size of any message to be encrypted.

=head2 NONCEBYTES

  my $nonce_size = $stream->NONCEBYTES;

Returns the size, in bytes, of a nonce.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::stream>

=item L<Crypt::Sodium::XS::stream/PRIMITIVES>

=item L<https://doc.libsodium.org/advanced/stream_ciphers>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/chacha20>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/xchacha20>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/salsa20>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/xsalsa20>

=back

=head1 FEEDBACK

For reporting bugs, giving feedback, submitting patches, etc. please use the
following:

=over 4

=item *

RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Crypt-Sodium-XS>

=item *

IRC channel C<#sodium> on C<irc.perl.org>.

=item *

Email the author directly.

=back

For any security sensitive reports, please email the author directly or contact
privately via IRC.

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
