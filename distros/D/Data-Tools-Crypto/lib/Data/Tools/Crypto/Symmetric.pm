##############################################################################
#
#  Data::Tools::Crypto::Symmetric perl module
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
#
#  freeze/thaw API actually uses JSON as safer option than Storable
#
##############################################################################
package Data::Tools::Crypto::Symmetric;
use strict;

use parent 'Data::Tools::Crypto';

use Encode qw( encode_utf8 decode_utf8 );
use Exception::Sink;
use Crypt::AuthEnc::ChaCha20Poly1305 qw( chacha20poly1305_encrypt_authenticate chacha20poly1305_decrypt_verify );
use Crypt::PRNG qw( random_bytes );

our $VERSION = '1.53';

my $NONCE_LEN = 12;
my $TAG_LEN   = 16;
my $FLAG_LEN  =  1;

sub new
{
  my $class = shift;
  my $key  = shift;
  my %opt   = @_;

  $class = ref( $class ) || $class;
  my $self = {};
  bless $self, $class;

  $self->reinit( $key, %opt );

  return $self;
}

# sub DESTROY
# {
#   my $self = shift;
# }

##############################################################################

# empty for now...
my %KNOWN_OPT = map { $_ => 1 } qw( );

sub reinit
{
  my $self = shift;
  my $key  = shift;
  my %opt  = @_;

  %$self = (); # clear state

  my @unknown = grep { ! $KNOWN_OPT{ $_ } } keys %opt;
  boom( "unknown option(s) [" . join( ',', sort @unknown ) . "]" ) if @unknown;

  boom( "key parameter is not defined or empty" ) unless defined $key and $key ne '';
  boom( "key parameter cannot be downgraded from UTF-8" ) if utf8::is_utf8( $key ) and ! utf8::downgrade( $key, 1 );
  my $kl = length( $key );
  boom( "invalid key size, expected 32 bytes, got [$kl]" ) unless $kl == 32;

  $self->{ 'KEY' } = $key;

  1;
}

##############################################################################

sub encrypt
{
  my $self  = shift;
  my $ptext = shift; # plaintext

  boom( "object state is undefined! use reinit() to setup first" ) unless defined $self->{ 'KEY' } and $self->{ 'KEY' } ne '';
  boom( "plaintext not defined" ) unless defined( $ptext );

  my $flag = 'b'; # binary
  if( utf8::is_utf8( $ptext ) )
    {
    $flag = 'u';
    $ptext = encode_utf8( $ptext );
    }

  my $nonce = random_bytes( $NONCE_LEN );
  my ( $ctext, $tag ) = chacha20poly1305_encrypt_authenticate( $self->{ 'KEY' }, $nonce, undef, $flag . $ptext );
  return $nonce . $ctext . $tag;
}

sub decrypt
{
  my $self  = shift;
  my $ctext = shift; # cryptotext

  boom( "object state is undefined! use reinit() to setup first" ) unless defined $self->{ 'KEY' } and $self->{ 'KEY' } ne '';
  boom( "cryptotext not defined" ) unless defined( $ctext );
  boom( "cryptotext must be binary, utf8 scalars are not supported" ) if utf8::is_utf8( $ctext );

  return undef if length( $ctext ) < $NONCE_LEN + $TAG_LEN + $FLAG_LEN;

  my $nonce = substr( $ctext, 0, $NONCE_LEN );
  my $tag   = substr( $ctext, -$TAG_LEN );
     $ctext = substr( $ctext, $NONCE_LEN, length( $ctext ) - $NONCE_LEN - $TAG_LEN );

  my $ptext = chacha20poly1305_decrypt_verify( $self->{ 'KEY' }, $nonce, undef, $ctext, $tag );

  return undef unless defined $ptext;

  my $flag  = substr( $ptext, 0, 1 );
     $ptext = substr( $ptext, 1    );

  if( $flag eq 'u' )
    {
    $ptext = decode_utf8( $ptext );
    }

  return $ptext;
}

##############################################################################

=pod


=head1 NAME

Data::Tools::Crypto::Symmetric - authenticated symmetric encryption with a shared secret key

=head1 SYNOPSIS

  use Data::Tools::Crypto::Symmetric;
  use Crypt::PRNG;
  use Exception::Sink;

  # the key is 32 raw bytes, not a passphrase

  my $key    = Crypt::PRNG::random_bytes( 32 );
  my $crypto = Data::Tools::Crypto::Symmetric->new( $key );

  # --------------------------------------------------------------------------

  my $ctext = $crypto->encrypt( $ptext );
  my $ptext = $crypto->decrypt( $ctext );

  boom( "data cannot be decrypted" ) unless defined $ptext;

  # --------------------------------------------------------------------------

  # the whole encoding and freeze/thaw API comes from
  # Data::Tools::Crypto, see there for the full list

  my $sealed = $crypto->freeze_base64url( { name => 'test' } );
  my $data   = $crypto->thaw_base64url( $sealed );

  # --------------------------------------------------------------------------

  # a new key can be set on an existing object

  $crypto->reinit( $another_key );

  # --------------------------------------------------------------------------

=head1 DESCRIPTION

Data::Tools::Crypto::Symmetric encrypts with ChaCha20-Poly1305, which is
authenticated: cryptotext which has been modified in any way will not decrypt
at all, rather than decrypting to wrong data. A fresh random nonce is used for
every message, so encrypting the same plaintext twice never gives the same
cryptotext.

Both sides need the same secret key. If there is no way to share one, use
Data::Tools::Crypto::RSA instead.

=head1 METHODS

=head2 new( $key )

Returns a new object. $key must be exactly 32 raw bytes, undef or an empty
key is refused. A key which perl
holds as characters is accepted if it can be represented as bytes, and is
converted, otherwise it is rejected -- 32 characters are not always 32 bytes.

There are no options yet. Unknown options are refused rather than silently
ignored.

=head2 reinit( $key )

Sets a new key on an existing object. All previous state is cleared first, so
if the key or an option is rejected the object is left without a key and is
not usable until a later reinit() succeeds. Catching the exception and
handling the unusable object is left to the caller.

=head2 encrypt( $plaintext )

Returns the cryptotext, which is always binary. There is no limit on the size
of the plaintext, the cryptotext is 29 bytes longer than the plaintext.

=head2 decrypt( $cryptotext )

Returns the plaintext, or undef if the cryptotext cannot be decrypted, which
covers a wrong key, modified data, truncated data and random input alike.
There is deliberately no more detail than that: telling these cases apart
would help an attacker more than a caller.

=head1 UTF8 HANDLING

encrypt()/decrypt() are transparent. Whatever goes in comes back out, with
the same value, the same length and in the same form. A byte string returns as
a byte string and a character string returns as a character string, which are
not the same thing in perl even when they print identically:

  my $chars = "caf\x{e9}";             # 4 characters
  my $bytes = "caf\xc3\xa9";           # 5 bytes, the utf8 encoding of it

  $crypto->decrypt( $crypto->encrypt( $chars ) );  # 4 characters back
  $crypto->decrypt( $crypto->encrypt( $bytes ) );  # 5 bytes back

Cryptotext is always binary. Passing a character string to decrypt() is a
mistake and raises an exception, rather than being silently mangled.

=head1 ERRORS

The two kinds of failure are reported differently and never confused:

  * a caller or configuration error raises an exception with boom(), i.e. a
    missing, empty or wrong sized key, an unknown option, an undefined
    argument, a character string where binary data is required, or any use
    of an object whose reinit() failed

  * data which simply does not decrypt returns undef, which is a normal
    result the caller is expected to check

=head1 DATA FORMAT

  nonce (12 bytes) . cryptotext . authentication tag (16 bytes)

The plaintext carries one leading marker byte, 'b' for binary or 'u' for a
character string, which is what makes the utf8 handling above transparent.
This accounts for the 29 bytes of overhead.

=head1 REQUIRED MODULES

Data::Tools::Crypto::Symmetric uses:

  * Data::Tools::Crypto
  * Crypt::AuthEnc::ChaCha20Poly1305 (CryptX)
  * Crypt::PRNG (CryptX)
  * Encode
  * Exception::Sink

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-data-tools-crypto

  git clone https://github.com/cade-vs/perl-data-tools-crypto.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/


=cut

##############################################################################

1;
