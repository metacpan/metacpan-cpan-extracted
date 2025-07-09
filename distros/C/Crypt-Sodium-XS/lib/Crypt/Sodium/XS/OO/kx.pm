package Crypt::Sodium::XS::OO::kx;
use strict;
use warnings;

use Crypt::Sodium::XS::kx;
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

sub primitives { keys %methods }

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

Crypt::Sodium::XS::OO::kx - Asymmetric (public/secret key) derivation from
client/server asymmetric key pairs

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

=head1 CONSTRUCTOR

=head2 new

  my $kx = Crypt::Sodium::XS::OO::kx->new;
  my $kx = Crypt::Sodium::XS::OO::kx->new(primitive => 'x25519blake2b');
  my $kx = Crypt::Sodium::XS->kx;

Returns a new kx object for the given primitive. If not given, the default
primitive is C<default>.

=head1 METHODS

=head2 PRIMITIVE

  my $kx = Crypt::Sodium::XS::OO::kx->new;
  my $default_primitive = $kx->PRIMITIVE;

=head2 PUBLICKEYBYTES

  my $public_key_length = $kx->PUBLICKEYBYTES;

=head2 SECRETKEYBYTES

  my $secret_key_length = $kx->SECRETKEYBYTES;

=head2 SEEDBYTES

  my $seed_length = $kx->SEEDKEYBYTES;

=head2 SESSIONKEYBYTES

  my $session_key_length = $kx->SESSIONKEYBYTES;

=head2 primitives

  my @primitives = $kx->primitives;

Returns a list of all supported primitive names (including 'default').

=head2 keypair

  my ($public_key, $secret_key) = $kx->keypair;
  my ($public_key, $secret_key) = $kx->keypair($seed);

C<$seed> is optional. If provided, it must be L</kx_SEEDBYTES> in length. Using
the same seed will generate the same key pair, so it must be kept confidential.
If omitted, a key pair is randomly generated.

=head2 client_session_keys

  my ($client_rx, $client_tx)
    = $kx->client_session_keys($client_pk, $client_sk, $server_pk);

=head2 server_session_keys

  my ($server_rx, $server_tx)
    = $kx->client_session_keys($server_pk, $server_sk, $client_pk);

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::kx>

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
