package Crypt::Sodium::XS::kem;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(
    CIPHERTEXTBYTES
    PUBLICKEYBYTES
    SECRETKEYBYTES
    SEEDBYTES
    SHAREDSECRETBYTES
  );

  my @bases = qw(
    dec
    enc
    keypair
  );

  my $default = [ map { "kem_$_" } @bases, @constant_bases, "PRIMITIVE" ];
  my $mlkem768 = [ map { "kem_mlkem768_$_" } @bases, @constant_bases ];
  my $xwing = [ map { "kem_xwing_$_" } @bases, @constant_bases ];

  our %EXPORT_TAGS = (
    all => [ @$default, @$mlkem768, @$xwing ],
    default => $default,
    mlkem768 => $mlkem768,
    xwing => $xwing,
  );

  our @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

package Crypt::Sodium::XS::OO::kem;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    CIPHERTEXTBYTES => \&Crypt::Sodium::XS::kem::kem_CIPHERTEXTBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::kem::kem_PRIMITIVE,
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::kem::kem_PUBLICKEYBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::kem::kem_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::kem::kem_SEEDBYTES,
    SHAREDSECRETBYTES => \&Crypt::Sodium::XS::kem::kem_SHAREDSECRETBYTES,
    dec => \&Crypt::Sodium::XS::kem::kem_dec,
    enc => \&Crypt::Sodium::XS::kem::kem_enc,
    keypair => \&Crypt::Sodium::XS::kem::kem_keypair,
  },
  mlkem768 => {
    CIPHERTEXTBYTES => \&Crypt::Sodium::XS::kem::kem_mlkem768_CIPHERTEXTBYTES,
    PRIMITIVE => sub { 'mlkem768' },
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::kem::kem_mlkem768_PUBLICKEYBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::kem::kem_mlkem768_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::kem::kem_mlkem768_SEEDBYTES,
    SHAREDSECRETBYTES => \&Crypt::Sodium::XS::kem::kem_mlkem768_SHAREDSECRETBYTES,
    dec => \&Crypt::Sodium::XS::kem::kem_mlkem768_dec,
    enc => \&Crypt::Sodium::XS::kem::kem_mlkem768_enc,
    keypair => \&Crypt::Sodium::XS::kem::kem_mlkem768_keypair,
  },
  xwing => {
    CIPHERTEXTBYTES => \&Crypt::Sodium::XS::kem::kem_xwing_CIPHERTEXTBYTES,
    PRIMITIVE => sub { 'xwing' },
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::kem::kem_xwing_PUBLICKEYBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::kem::kem_xwing_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::kem::kem_xwing_SEEDBYTES,
    SHAREDSECRETBYTES => \&Crypt::Sodium::XS::kem::kem_xwing_SHAREDSECRETBYTES,
    dec => \&Crypt::Sodium::XS::kem::kem_xwing_dec,
    enc => \&Crypt::Sodium::XS::kem::kem_xwing_enc,
    keypair => \&Crypt::Sodium::XS::kem::kem_xwing_keypair,
  },
);

sub Crypt::Sodium::XS::kem::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::kem::primitives;
*available = \&Crypt::Sodium::XS::kem::available;

sub CIPHERTEXTBYTES { my $self = shift; goto $methods{$self->{primitive}}->{CIPHERTEXTBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub PUBLICKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{PUBLICKEYBYTES}; }
sub SECRETKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SECRETKEYBYTES}; }
sub SEEDBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SEEDBYTES}; }
sub SHAREDSECRETBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SHAREDSECRETBYTES}; }
sub dec { my $self = shift; goto $methods{$self->{primitive}}->{dec}; }
sub enc { my $self = shift; goto $methods{$self->{primitive}}->{enc}; }
sub keypair { my $self = shift; goto $methods{$self->{primitive}}->{keypair}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::kem - Key encapsulation

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  use Crypt::Sodium::XS::kem;
  die "no kem support" unless Crypt::Sodium::XS::kem->available;

  my $kem = Crypt::Sodium::XS->kem;

  # server:
  my ($pk, $sk) = $kem->keypair;
  # $pk is made available to client in trustworthy manner

  # client:
  my ($ct, $client_ss) = $kem->enc($pk);
  # $ct is transferred to server

  # server:
  my $server_ss = $kem->dec($ct, $sk);

  # both sides have shared secret
  print "secrets match!\n" if $client_ss->compare($server_ss) == 0;

=head1 DESCRIPTION

A key encapsulation mechanism creates a shared secret for a recipient using the
public key of that recipient.

The sender obtains the shared secret directly during encapsulation. The
recipient obtains the same shared secret by decapsulating the ciphertext with
the secret key.

This is useful for bootstrapping session keys or building hybrid encryption
schemes.

Unlike traditional Diffie-Hellman style key exchange, encapsulation is
asymmetric: only the recipient needs a long-term key pair, and the sender does
not need to publish a public key in order to create a shared secret.

If the application needs sender authentication in addition to confidentiality,
combine key encapsulation with a signature scheme or an authenticated key
exchange.

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>kem> method.

  my $kem = Crypt::Sodium::XS->kem;
  my $kem = Crypt::Sodium::XS->kem(primitive => 'mlkem768');

Returns a new kem object.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::kem>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $kem->primitive;
  $kem->primitive('mlkem768');

Gets or sets the primitive used for all operations by this object. It must be
one of the primitives listed in L</PRIMITIVES>, including C<default>.

=head1 METHODS

=head2 available

  my $has_kem = $kem->available;
  my $has_kem = Crypt::Sodium::XS::kem->available;

Returns true if L<Crypt::Sodium::XS> supports KEM, false otherwise. KEM will
only be supported if L<Crypt::Sodium::XS> was built with a new enough version
of libsodium (at least 1.0.22).

Can be called as a class method.

=head2 primitives

  my @primitives = $kem->primitives;
  my @primitives = Crypt::Sodium::XS::kem->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $kem->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 dec

  my $shared_secret = $kem->dec($ciphertext, $secret_key, $flags);

C<$ciphertxt> is the encrypted ciphertext received from the sender. It must be
L</CIPHERTEXTBYTES> bytes.

C<$secret_key> is the secret key used to decrypt the ciphertext. It must be
L</SECRETKEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$shared_secret>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the shared secret of
L</SHAREDSECRETBYTES> bytes.

TODO

=head2 enc
  
  my ($ciphertext, $shared_secret) = $kem->enc($public_key, $flags);

C<$public_key> is the receiver's public key to which C<$ciphertext> is
encrypted.

C<$flags> is optional. It is the flags used for the C<$shared_secret>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns the encrypted ciphertext of L</CIPHERTEXTBYTES> bytes and a
L<Crypt::Sodium::XS::MemVault>: the shared secret of L</SHAREDSECRETBYTES>
bytes.

=head2 keypair

  my ($public_key, $secret_key) = $kem->keypair($seed, $flags);

C<$seed> is optional. It must be L</SEEDBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Using the same seed will generate the same key
pair, so it must be kept confidential. If omitted, a key pair is randomly
generated.

C<$flags> is optional. It is the flags used for the C<$secret_key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a public key of L</PUBLICKEYBYTES> bytes and a
L<Crypt::Sodium::XS::MemVault>: the secret key of L</SECRETKEYBYTES> bytes.

=head2 CIPHERTEXTBYTES

Returns the size, in bytes, of ciphertext produced by L</enc>.

=head2 PUBLICKEYBYTES

Returns the size, in bytes, of a public key.

=head2 SECRETKEYBYTES

Returns the size, in bytes, of a private key.

=head2 SHAREDSECRETBYTES

Returns the size, in bytes, of a shared secret.

=head2 SEEDBYTES

Returns the size, in bytes, of a seed used by L</keypair>.

=head1 PRIMITIVES

=over 4

=item * mlkem768

=item * xwing (default)

X-Wing combines ML-KEM768 with X25519 in order to provide protection against
both classical and quantum adversaries.

=back

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead or in addition.

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<kem_E<lt>primitiveE<gt>_*> functions and constants for that primitive. A
C<:all> tag imports everything.

=head2 kem_dec

=head2 kem_E<lt>primitiveE<gt>_dec

  my $shared_secret = kem_dec($ciphertext, $secret_key);

Same as L</dec>.

=head2 kem_enc

=head2 kem_E<lt>primitiveE<gt>_enc

  my ($ciphertext, $shared_secret) = kem_enc($public_key);

Same as L</enc>.

=head2 kem_keypair

=head2 kem_E<lt>primitiveE<gt>_keypair

  my ($public_key, $secret_key) = kem_keypair;

=head1 CONSTANTS

Same as L</keypair>.

=head2 kem_CIPHERTEXTBYTES

=head2 kem_E<lt>primitiveE<gt>_CIPHERTEXTBYTES

Same as L</CIPHERTEXTBYTES>.

=head2 kem_PUBLICKEYBYTES

=head2 kem_E<lt>primitiveE<gt>_PUBLICKEYBYTES

Same as L</PUBLICKEYBYTES>.

=head2 kem_SECRETKEYBYTES

=head2 kem_E<lt>primitiveE<gt>_SECRETKEYBYTES

Same as L</SECRETKEYBYTES>.

=head2 kem_SHAREDSECRETBYTES

=head2 kem_E<lt>primitiveE<gt>_SHAREDSECRETBYTES

Same as L</SHAREDSECRETBYTES>.

=head2 kem_SEEDBYTES

=head2 kem_E<lt>primitiveE<gt>_SEEDBYTES

Same as L</SEEDBYTES>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://libsodium.gitbook.io/doc/public-key_cryptography/key_encapsulation>

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

Copyright (c) 2026 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
