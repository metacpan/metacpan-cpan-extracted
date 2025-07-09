package Crypt::Sodium::XS::kx;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

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

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::kx - Asymmetric (public/secret key) derivation from
client/server asymmetric key pairs

=head1 SYNOPSIS

  use Crypt::Sodium::XS::kx ":default";

  # client
  my ($client_pk, $client_sk) = kx_keypair();
  my ($server_pk, $server_sk) = kx_keypair();

  # client must have server's public key
  # shared keys for server->client (client_rx) and client->server (client_tx)
  my ($client_rx, $client_tx)
    = kx_client_session_keys($client_pk, $client_sk, $server_pk);

  # server must have client's public key
  # shared keys for client->server (server_rx) and server->client (server_tx)
  my ($server_rx, $server_tx)
    = kx_client_session_keys($server_pk, $server_sk, $client_pk);

=head1 DESCRIPTION

Using L<Crypt::Sodium::XS::kx>, two parties can securely compute a set of
shared keys using their peer's public key and their own secret key.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants as documented below. A separate import tag is provided for each of
the primitives listed in L</PRIMITIVES>. For example, C<:x25519blake2b> imports
C<kx_x25519blake2b_client_session_keys>. You should use at least one import
tag.

=head2 kx_keypair

  my ($public_key, $secret_key) = kx_keypair();
  my ($public_key, $secret_key) = kx_keypair($seed);

C<$seed> is optional. If provided, it must be L</kx_SEEDBYTES> in length. Using
the same seed will generate the same key pair, so it must be kept confidential.
If omitted, a key pair is randomly generated.

=head2 kx_client_session_keys

  my ($client_rx, $client_tx)
    = kx_client_session_keys($client_pk, $client_sk, $server_pk);

=head2 kx_server_session_keys

  my ($server_rx, $server_tx)
    = kx_client_session_keys($server_pk, $server_sk, $client_pk);

=head1 CONSTANTS

=head2 kx_PRIMITIVE

  my $default_primitive = kx_PRIMITIVE();

=head2 kx_PUBLICKEYBYTES

  my $public_key_length = kx_PUBLICKEYBYTES();

=head2 kx_SECRETKEYBYTES

  my $secret_key_length = kx_SECRETKEYBYTES();

=head2 kx_SEEDBYTES

  my $seed_length = kx_SEEDKEYBYTES();

=head2 kx_SESSIONKEYBYTES

  my $session_key_length = kx_SESSIONKEYBYTES();

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<kx_E<lt>primitiveE<gt>>-prefixed couterparts (e.g.,
kx_x25519blake2b_keypair, kx_x25519blake2b_PUBLICKEYBYTES).

=over 4

=item * x25519blake2b

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::kx>

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
