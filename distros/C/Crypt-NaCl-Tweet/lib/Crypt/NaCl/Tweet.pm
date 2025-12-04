package Crypt::NaCl::Tweet;
use strict;
use warnings;
BEGIN {
  our $VERSION = '0.06';
  require XSLoader;
  XSLoader::load(__PACKAGE__, $VERSION);
}

use Exporter 'import';
our %EXPORT_TAGS = (
  box => [qw[
    box_PRIMITIVE
    box_PUBLICKEYBYTES
    box_SECRETKEYBYTES
    box_BEFORENMBYTES
    box_NONCEBYTES
    box_ZEROBYTES
    box_BOXZEROBYTES
    box
    box_afternm
    box_beforenm
    box_keypair
    box_open
    box_open_afternm
  ]],
  core => [qw[
    core_hsalsa20_CONTSBYTES
    core_hsalsa20_KEYBYTES
    core_hsalsa20_INPUTBYTES
    core_hsalsa20_OUTPUTBYTES
    core_salsa20_CONTSBYTES
    core_salsa20_KEYBYTES
    core_salsa20_INPUTBYTES
    core_salsa20_OUTPUTBYTES
    core_hsalsa20
    core_salsa20
  ]],
  hash => [qw[
    hash_BYTES
    hash_PRIMITIVE
    hash
  ]],
  hashblocks => [qw[
    hashblocks_BLOCKBYTES
    hashblocks_PRIMITIVE
    hashblocks
  ]],
  onetimeauth => [qw[
    onetimeauth_BYTES
    onetimeauth_KEYBYTES
    onetimeauth_PRIMITIVE
    onetimeauth
    onetimeauth_keygen
    onetimeauth_verify
  ]],
  random => [qw[ random_bytes ]],
  secretbox => [qw[
    secretbox_KEYBYTES
    secretbox_NONCEBYTES
    secretbox_PRIMITIVE
    secretbox_ZEROBYTES
    secretbox_BOXZEROBYTES
    secretbox
    secretbox_open
  ]],
  scalarmult => [qw[
    scalarmult_BYTES
    scalarmult_PRIMITIVE
    scalarmult_SCALARBYTES
    scalarmult
    scalarmult_base
  ]],
  sign => [qw[
    sign_BYTES
    sign_PRIMITIVE
    sign_PUBLICKEYBYTES
    sign_SECRETKEYBYTES
    sign
    sign_keypair
    sign_open
  ]],
  stream => [qw[
    stream_KEYBYTES
    stream_NONCEBYTES
    stream_PRIMITIVE
    stream
    stream_keygen
    stream_xor
  ]],
  verify => [qw[
    verify_BYTES
    verify_16_BYTES
    verify_32_BYTES
    verify
    verify_16
    verify_32
  ]],
);
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = [ @EXPORT_OK ];

use constant box_PRIMITIVE => "curve25519xsalsa20poly1305";
use constant box_PUBLICKEYBYTES => 32;
use constant box_SECRETKEYBYTES => 32;
use constant box_BEFORENMBYTES => 32;
use constant box_NONCEBYTES => 24;
use constant box_ZEROBYTES => 32;
use constant box_BOXZEROBYTES => 16;
use constant hash_BYTES => 64;
use constant hash_PRIMITIVE => "sha512";
use constant hashblocks_BLOCKBYTES => 128;
use constant hashblocks_PRIMITIVE => "sha512";
use constant hashblocks_STATEBYTES => 64;
use constant onetimeauth_BYTES => 16;
use constant onetimeauth_KEYBYTES => 32;
use constant onetimeauth_PRIMITIVE => "poly1305";
use constant scalarmult_BYTES => 32;
use constant scalarmult_PRIMITIVE => "curve25519";
use constant scalarmult_SCALARBYTES => 32;
use constant secretbox_KEYBYTES => 32;
use constant secretbox_NONCEBYTES => 24;
use constant secretbox_PRIMITIVE => "xsalsa20poly1305";
use constant secretbox_ZEROBYTES => 32;
use constant secretbox_BOXZEROBYTES => 16;
use constant sign_BYTES => 64;
use constant sign_PRIMITIVE => "ed25519";
use constant sign_PUBLICKEYBYTES => 32;
use constant sign_SECRETKEYBYTES => 64;
use constant stream_KEYBYTES => 32;
use constant stream_NONCEBYTES => 24;
use constant stream_PRIMITIVE => "xsalsa20";
use constant verify_BYTES => 16;
use constant verify_16_BYTES => 16;
use constant verify_32_BYTES => 32;

sub box_keypair {
  my $sk = random_bytes(32);
  my $pk = scalarmult_base($sk);
  return ($pk, $sk);
}

sub onetimeauth_keygen { random_bytes(onetimeauth_KEYBYTES) }

sub stream_keygen { random_bytes(stream_KEYBYTES) }

sub random_bytes;
if (eval { require Sys::GetRandom; 1; }) {
  *random_bytes = sub { Sys::GetRandom::random_bytes($_[0]) };
}
elsif (eval { require Crypt::PRNG; 1; }) {
  *random_bytes = sub { Crypt::PRNG::random_bytes($_[0]) };
}
elsif (eval { require Crypt::URandom; 1; }) {
  *random_bytes = sub { Crypt::URandom::urandom($_[0]); };
}
# probably others...
else {
  *random_bytes = sub {
    die "no random_bytes implementation is available on this system. ",
        "you could install Sys::GetRandom, Crypt::PRNG, or Crypt::URandom."
  };
}

1;

__END__

=encoding utf8

=head1 NAME

Crypt::NaCl::Tweet - XS bindings for TweetNaCl

=head1 SYNOPSIS

  use Crypt::NaCl::Tweet ":all"

  # TODO for now. sorry. see below.

=head1 DESCRIPTION

L<TweetNaCl|https://tweetnacl.cr.yp.to/index.html> is an implementation of
the L<NaCl|https://nacl.cr.yp.to/> cryptographic library which fits into 100
tweets. Cute trick, but it also makes for a more digestable/auditable
self-contained library.  L<Crypt::NaCl::Tweet> includes, and provides perl
bindings to, that library.

See the documentation available on the L<NaCl|https://nacl.cr.yp.to/> website
for more information about the purpose and design of the available functions.
Note that the C<crypto_> prefixes (and C<_tweet> suffixes) are stripped from
function names for ease of use.

Functions and constants documented below are sorted into their high-level
primitives.

=head2 box

=head3 FUNCTIONS

=over 4

=item box

  my $ciphertext = box($msg, $nonce, $their_public_key, $my_secret_key);

=item box_afternm

  my $ciphertext = box_afternm($msg, $nonce, $key);

=item box_beforenm

  my $key = box_beforenm($their_public_key, $my_secret_key);

=item box_keypair

  my ($public_key, $secret_key) = box_keypair();

=item box_open

  my $plaintext = box_open($ciphertext, $nonce, $their_public_key, $my_secret_key);

=item box_open_afternm

  my $plaintext = box_open_afternm($ciphertext, $nonce, $key);

=back

=head3 CONSTANTS

=over 4

=item box_PRIMITIVE

=item box_PUBLICKEYBYTES

=item box_SECRETKEYBYTES

=item box_BEFORENMBYTES

=item box_NONCEBYTES

=item box_ZEROBYTES

=item box_BOXZEROBYTES

=back

=head2 hash

=head3 FUNCTIONS

=over 4

=item hash

  my $binary_hash = hash($msg);

=back

=head3 CONSTANTS

=over 4

=item hash_BYTES

=item hash_PRIMITIVE

=back

=head2 onetimeauth

=head3 FUNCTIONS

=over 4

=item onetimeauth

  my $authenticator = onetimeauth($msg, $key);

=item onetimeauth_keygen

  my $auth_key = onetimeauth_keygen();

=item onetimeauth_verify

  my $is_valid = onetimeauth_verify($authenticator, $msg, $key);

=back

=head3 CONSTANTS

=over 4

=item onetimeauth_BYTES

=item onetimeauth_KEYBYTES

=item onetimeauth_PRIMITIVE

=back

=head2 scalarmult

=head3 FUNCTIONS

=over 4

=item scalarmult

  my $q = scalarmult($n, $p);

Low-level function.

=item scalarmult_base

  my $q = scalarmult_base($n);

Low-level function.

=back

=head3 CONSTANTS

=over 4

=item scalarmult_BYTES

=item scalarmult_PRIMITIVE

=item scalarmult_SCALARBYTES

=back

=head2 secretbox

=head3 FUNCTIONS

=over 4

=item secretbox

  my $ciphertext = secretbox($msg, $nonce, $key);

=item secretbox_open

  my $plaintext = secretbox_open($ciphertext, $nonce, $key);

=back

=head3 CONSTANTS

=over 4

=item secretbox_KEYBYTES

=item secretbox_NONCEBYTES

=item secretbox_PRIMITIVE

=item secretbox_ZEROBYTES

=item secretbox_BOXZEROBYTES

=back

=head2 sign

=head3 FUNCTIONS

=over 4

=item sign

  my $signed_msg = sign($msg, $secret_key);

=item sign_keypair

  my ($public_key, $secret_key) = sign_keypair();

=item sign_open

  my $msg = sign_open($signed_msg, $public_key);

returns undef if signature is not valid.

=back

=head3 CONSTANTS

=over 4

=item sign_BYTES

=item sign_PRIMITIVE

=item sign_PUBLICKEYBYTES

=item sign_SECRETKEYBYTES

=back

=head2 stream

=head3 FUNCTIONS

=over 4

=item stream

  my $stream_bytes = stream($nbytes, $nonce, $key);

=item stream_keygen

  my $stream_key = stream_keygen();

=item stream_xor

  my $ciphertext = stream_xor($msg, $nonce, $key);

=back

=head3 CONSTANTS

=over 4

=item stream_KEYBYTES

=item stream_NONCEBYTES

=item stream_PRIMITIVE

=back

=head2 verify

=head3 FUNCTIONS

=over 4

=item verify, verify_16

  my $is_equal = verify($x, $y);
  my $is_equal = verify_16($x, $y);

Constant-time. C<$x> and C<$y> must be 16 bytes.

=item verify_32

  my $is_equal = verify_32($x, $y);

Constant-time. C<$x> and C<$y> must be 32 bytes.

=back

=head3 CONSTANTS

=over 4

=item verify_BYTES

Sixteen.

=item verify_16_BYTES

Sixteen.

=item verify_32_BYTES

Thirty-two.

=back

=head1 BUGS/KNOWN LIMITATIONS

TweetNaCl is a very minimal library, and this is (at time of writing) a new
distribution. Docs and tests are lacking. Patches welcome!

=head1 FEEDBACK

For reporting bugs, giving feedback, submitting patches, etc. please use the
following:

=over 4

=item *

RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Crypt-NaCl-Tweet>

=item *

Email the author directly.

=back

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2025 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
