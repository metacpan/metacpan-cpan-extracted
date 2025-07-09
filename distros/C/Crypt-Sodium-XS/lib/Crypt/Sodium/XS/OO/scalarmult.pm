package Crypt::Sodium::XS::OO::scalarmult;
use strict;
use warnings;

use Crypt::Sodium::XS::scalarmult;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_BYTES,
    PRIMITIVE => sub { 'curve25519' },
    SCALARBYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_SCALARBYTES,
    base => \&Crypt::Sodium::XS::scalarmult::scalarmult_base,
    keygen => \&Crypt::Sodium::XS::scalarmult::scalarmult_keygen,
    scalarmult => \&Crypt::Sodium::XS::scalarmult::scalarmult,
  },

);

sub primitives { 'default' }

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES}; }
sub SCALARBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SCALARBYTES}; }
sub base { my $self = shift; goto $methods{$self->{primitive}}->{base}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub scalarmult { my $self = shift; goto $methods{$self->{primitive}}->{scalarmult}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::scalarmult - Point-scalar multiplication over the
edwards25519 curve

=head1 SYNOPSIS

  use Crypt::Sodium::XS 'sodium_random_bytes';
  my $scalarmult = Crypt::Sodium::XS->scalarmult;

  my $keysize = Crypt::Sodium::XS->box->SECRETKEYBYTES;
  my $client_sk = sodium_random_bytes($keysize);
  my $client_pk = $scalarmult->base($client_sk);
  my $server_sk = sodium_random_bytes($keysize);
  my $server_pk = $scalarmult->base($client_sk);

  # do not use output directly for key exchange. use Crypt::Sodium::XS::kx.
  # a better shared key with scalarmult looks like:

  # client side:
  my $q = $scalarmult->scalarmult($client_sk, $server_pk);
  my $hasher = Crypt::Sodium::XS->generichash->init;
  $hasher->update($q, $client_pk, $server_pk);
  my $client_shared_secret = $hasher->final;

  # server side:
  my $q = $scalarmult->scalarmult($server_sk, $client_pk);
  my $hasher = Crypt::Sodium::XS->generichash->init;
  $hasher->update($q, $client_pk, $server_pk);
  my $server_shared_secret = $hasher->final;

  # $client_shared_secret and $server_shared_secret are now identical keys.

=head1 DESCRIPTION

L<Crypt::Sodium::XS::scalarmult> provides an API to multiply a point on the
edwards25519 curve.

This can be used as a building block to construct key exchange mechanisms, or
more generally to compute a public key from a secret key. For key exchange, you
generally want to use L<Crypt::Sodium::XS::kx> instead.

=head1 CONSTRUCTOR

=head2 new

  my $scalarmult = Crypt::Sodium::XS::OO::scalarmult->new;
  my $pwhash = Crypt::Sodium::XS->scalarmult;

Returns a new scalarmult object.

=head1 METHODS

=head2 BYTES

  my $out_size = $scalarmult->BYTES

=head2 SCALARBYTES

  my $out_size = $scalarmult->SCALARBYTES

=head2 keygen

  my $secret_key = $scalarmult->keygen;

=head2 base

  my $public_key = $scalarmult->base($secret_key);

=head2 scalarmult

  my $q = $scalarmult->scalarmult($my_secret_key, $their_public_key);

Computes a shared secret q given a user’s secret key and another user’s public
key.

C<$my_secret_key> is L</SCALARBYTES> bytes long, C<$their_public_key> and the
output are L</BYTES> bytes long.

C<$q> represents the X coordinate of a point on the curve. As a result, the
number of possible keys is limited to the group size (≈2^252), which is smaller
than the key space. For this reason, and to mitigate subtle attacks due to the
fact many (p, n) pairs produce the same result, using the output of the
multiplication q directly as a shared key is not recommended. See the
L</SYNOPSIS>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::scalarmult>

=item L<https://doc.libsodium.org/advanced/scalar_multiplication>

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
