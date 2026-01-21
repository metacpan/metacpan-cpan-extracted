package Crypt::Sodium::XS::kx;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(
    PUBLICKEYBYTES
    SECRETKEYBYTES
    SEEDBYTES
    SESSIONKEYBYTES
  );

  my @bases = qw(
    keypair
    client_session_keys
    server_session_keys
  );

  my $default = [
    (map { "kx_$_" } @bases),
    (map { "kx_$_" } @constant_bases, "PRIMITIVE"),
  ];
  my $x25519blake2b = [
    (map { "kx_x25519blake2b_$_" } @bases),
    (map { "kx_x25519blake2b_$_" } @constant_bases),
  ];

  our %EXPORT_TAGS = (
    all => [ @$default, @$x25519blake2b ],
    default => $default,
    x25519blake2b => $x25519blake2b,
  );

  our @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

package Crypt::Sodium::XS::OO::kx;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    PRIMITIVE => \&Crypt::Sodium::XS::kx::kx_PRIMITIVE,
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::kx::kx_PUBLICKEYBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::kx::kx_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::kx::kx_SEEDBYTES,
    SESSIONKEYBYTES => \&Crypt::Sodium::XS::kx::kx_SESSIONKEYBYTES,
    keypair => \&Crypt::Sodium::XS::kx::kx_keypair,
    client_session_keys => \&Crypt::Sodium::XS::kx::kx_client_session_keys,
    server_session_keys => \&Crypt::Sodium::XS::kx::kx_server_session_keys,
  },
  x25519blake2b => {
    PRIMITIVE => sub { 'x25519blake2b' },
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::kx::kx_x25519blake2b_PUBLICKEYBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::kx::kx_x25519blake2b_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::kx::kx_x25519blake2b_SEEDBYTES,
    SESSIONKEYBYTES => \&Crypt::Sodium::XS::kx::kx_x25519blake2b_SESSIONKEYBYTES,
    keypair => \&Crypt::Sodium::XS::kx::kx_x25519blake2b_keypair,
    client_session_keys => \&Crypt::Sodium::XS::kx::kx_x25519blake2b_client_session_keys,
    server_session_keys => \&Crypt::Sodium::XS::kx::kx_x25519blake2b_server_session_keys,
  },
);

sub Crypt::Sodium::XS::kx::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::kx::primitives;

sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub PUBLICKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{PUBLICKEYBYTES}; }
sub SECRETKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SECRETKEYBYTES}; }
sub SEEDBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SEEDBYTES}; }
sub SESSIONKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SESSIONKEYBYTES}; }
sub keypair { my $self = shift; goto $methods{$self->{primitive}}->{keypair}; }
sub client_session_keys { my $self = shift; goto $methods{$self->{primitive}}->{client_session_keys}; }
sub server_session_keys { my $self = shift; goto $methods{$self->{primitive}}->{server_session_keys}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::kx - Shared key derivation from client/server asymmetric key
pairs

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  my $kx = Crypt::Sodium::XS->kx;

  # client
  my ($client_pk, $client_sk) = $kx->keypair;
  my ($server_pk, $server_sk) = $kx->keypair;

  # client must have server's public key
  # shared keys for server->client (client_rx) and client->server (client_tx)
  my ($client_rx, $client_tx)
    = $kx->client_session_keys($client_pk, $client_sk, $server_pk);

  # server must have client's public key
  # shared keys for client->server (server_rx) and server->client (server_tx)
  my ($server_rx, $server_tx)
    = $kx->client_session_keys($server_pk, $server_sk, $client_pk);

=head1 DESCRIPTION

Using L<Crypt::Sodium::XS::kx>, two parties can securely compute a set of
shared keys using their peer's public key and their own secret key.

One party must act as the "client" side of communications. The other party must
act as the "server" side of communications.

The shared keys can be used used with symmetric encryption protocols such as
L<Crypt::Sodium::XS::secretbox> and L<Crypt::Sodium::XS::aead>.

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>kx> method.

  my $kx = Crypt::Sodium::XS->kx;
  my $kx = Crypt::Sodium::XS->kx(primitive => 'x25519blake2b');

Returns a new kx object.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::kx>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $kx->primitive;
  $kx->primitive('x25519blake2b');

Gets or sets the primitive used for all operations by this object. It must be
one of the primitives listed in L</PRIMITIVES>, including C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = $kx->primitives;
  my @primitives = Crypt::Sodium::XS::kx->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $kx->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 keypair

  my ($public_key, $secret_key) = $kx->keypair($seed, $flags);

C<$seed> is optional. It must be L</SEEDBYTES> in length. It may be a
L<Crypt::Sodium::XS::MemVault>. Using the same seed will generate the same key
pair, so it must be kept confidential. If omitted, a key pair is randomly
generated.

C<$flags> is optional. It is the flags used for the C<$secret_key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a public key of L</PUBLICKEYBYTES> bytes and a
L<Crypt::Sodium::XS::MemVault>: the secret key of L</SECRETKEYBYTES> bytes.

=head2 client_session_keys

  my ($client_rx, $client_tx)
    = $kx->client_session_keys($client_pk, $client_sk, $server_pk, $flags);

C<$client_pk> is a public key. It must be L</PUBLICKEYBYTES> bytes.

C<$client_sk> is a secret key. It must be L</SECRETKEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$server_pk> is a public key. It must be L</PUBLICKEYBYTES> bytes.

C<$flags> is optional. It is the flags used for both the C<$client_rx> and
C<$client_tx> L<Crypt::Sodium::XS::MemVault>s. See
L<Crypt::Sodium::XS::ProtMem>.

Returns two L<Crypt::Sodium::XS::MemVault>s: a secret key of L</SECRETKEYBYTES>
bytes intended for decrypting on the client side, and a secret key of
L</SECRETKEYBYTES> intended for encrypting on the client side.

=head2 server_session_keys

  my ($server_rx, $server_tx)
    = $kx->client_session_keys($server_pk, $server_sk, $client_pk, $flags);

C<$server_pk> is a public key. It must be L</PUBLICKEYBYTES> bytes.

C<$server_sk> is a secret key. It must be L</SECRETKEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$client_pk> is a public key. It must be L</PUBLICKEYBYTES> bytes.

C<$flags> is optional. It is the flags used for both the C<$server_rx> and
C<$server_tx> L<Crypt::Sodium::XS::MemVault>s. See
L<Crypt::Sodium::XS::ProtMem>.

Returns two L<Crypt::Sodium::XS::MemVault>s: a secret key of L</SECRETKEYBYTES>
bytes intended for decrypting on the server side, and a secret key of
L</SECRETKEYBYTES> intended for encrypting on the server side.

=head2 PUBLICKEYBYTES

  my $public_key_length = $kx->PUBLICKEYBYTES;

The size, in bytes, of a public key.

=head2 SECRETKEYBYTES

  my $secret_key_length = $kx->SECRETKEYBYTES;

The size, in bytes, of a secret key.

=head2 SEEDBYTES

  my $seed_length = $kx->SEEDKEYBYTES;

The size, in bytes, of a seed used by L</keypair>.

=head2 SESSIONKEYBYTES

  my $session_key_length = $kx->SESSIONKEYBYTES;

The size, in bytes, of a secret shared session key.

=head1 PRIMITIVES

=over 4

=item * x25519blake2b (default)

=back

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead or in addition.

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<kx_E<lt>primitiveE<gt>_*> functions and constants for that primitive. A
C<:all> tag imports everything.

=head2 kx_keypair

=head2 kx_E<lt>primitiveE<gt>_keypair

  my ($public_key, $secret_key) = kx_keypair($seed, $flags);

Same as L</keypair>.

=head2 kx_client_session_keys

=head2 kx_E<lt>primitiveE<gt>_client_session_keys

  my ($client_rx, $client_tx)
    = kx_client_session_keys($client_pk, $client_sk, $server_pk, $flags);

Same as L</client_session_keys>.

=head2 kx_server_session_keys

=head2 kx_E<lt>primitiveE<gt>_server_session_keys

  my ($server_rx, $server_tx)
    = kx_client_session_keys($server_pk, $server_sk, $client_pk, $flags);

Same as L</server_session_keys>.

=head1 CONSTANTS

=head2 kx_PRIMITIVE

  my $default_primitive = kx_PRIMITIVE();

Returns the name of the default primitive.

=head2 kx_PUBLICKEYBYTES

=head2 kx_E<lt>primitiveE<gt>_PUBLICKEYBYTES

Same as L</PUBLICKEYBYTES>.

=head2 kx_SECRETKEYBYTES

=head2 kx_E<lt>primitiveE<gt>_SECRETKEYBYTES

  my $secret_key_length = kx_SECRETKEYBYTES();

Same as L</SECRETKEYBYTES>.

=head2 kx_SEEDBYTES

=head2 kx_E<lt>primitiveE<gt>_SEEDBYTES

  my $seed_length = kx_SEEDKEYBYTES();

Same as L</SEEDBYTES>.

=head2 kx_SESSIONKEYBYTES

=head2 kx_E<lt>primitiveE<gt>_SESSIONKEYBYTES

  my $session_key_length = kx_SESSIONKEYBYTES();

Same as L</SESSIONKEYBYTES>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://doc.libsodium.org/key_exchange>

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

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
