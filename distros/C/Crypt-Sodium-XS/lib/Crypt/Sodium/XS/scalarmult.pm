package Crypt::Sodium::XS::scalarmult;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

# really no primitive-specific anything here, just being consistent.

my @constant_bases = qw(
  BYTES
  SCALARBYTES
);

my @bases = qw(
  keygen
  base
);

my $default = [
  'scalarmult',
  (map { "scalarmult_$_" } @bases),
  (map { "scalarmult_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all => [ @$default ],
  default => $default,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::scalarmult - Point-scalar multiplication over the
edwards25519 curve

=head1 SYNOPSIS

  use Crypt::Sodium::XS::scalarmult ':default';
  use Crypt::Sodium::XS 'sodium_random_bytes';

  my $keysize = Crypt::Sodium::XS->box->SECRETKEYBYTES;
  my $client_sk = sodium_random_bytes($keysize);
  my $client_pk = scalarmult_base($client_sk);
  my $server_sk = sodium_random_bytes($keysize);
  my $server_pk = scalarmult_base($client_sk);

  # do not use output directly for key exchange use Crypt::Sodium::XS::kx.
  # or, if you insist:

  use Crypt::Sodium::XS::generichash 'generichash_init';

  # client side:
  my $q = scalarmult($client_sk, $server_pk);
  my $hasher = generichash_init();
  $hasher->update($q, $client_pk, $server_pk);
  my $client_shared_secret = $hasher->final;

  # server side:
  my $q = scalarmult($server_sk, $client_pk);
  my $hasher = generichash_init();
  $hasher->update($q, $client_pk, $server_pk);
  my $server_shared_secret = $hasher->final;

  # $client_shared_secret and $server_shared_secret are now identical keys.

=head1 DESCRIPTION

L<Crypt::Sodium::XS::scalarmult> provides an API to multiply a point on the
edwards25519 curve.

This can be used as a building block to construct key exchange mechanisms, or
more generally to compute a public key from a secret key. For key exchange, you
generally want to use L<Crypt::Sodium::XS::kx> instead.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants as documented below.

=head2 scalarmult_keygen

  my $secret_key = scalarmult_keygen();

=head2 scalarmult_base

  my $public_key = scalarmult_base($secret_key);

=head2 scalarmult

  my $q = scalarmult($my_secret_key, $their_public_key);

=head1 CONTSANTS

=head2 scalarmult_BYTES

  my $public_key_length = scalarmult_BYTES();

=head2 scalarmult_SCALARBYTES

  my $shared_and_secret_key_length = scalarmult_SCALARBYTES();

=head1 PRIMITIVES

There are no primitive-specific functions for this module. It always uses
X25519 (ECDH over Curve25519). See L<RFC
7748|https://www.rfc-editor.org/rfc/rfc7748.txt>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::scalarmult>

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
