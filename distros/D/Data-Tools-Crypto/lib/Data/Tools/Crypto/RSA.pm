##############################################################################
#
#  Data::Tools::Crypto::RSA perl module
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
#  encryption is hybrid: a fresh symmetric key is generated for each message,
#  the message is encrypted with it and the key itself is wrapped with RSA.
#  RSA alone can only encrypt keysize-2*hashsize-2 bytes (190 for a 2048-bit
#  key with SHA256), hybrid encryption removes that limit entirely and adds
#  authentication of the payload. note that anyone holding the public key can
#  still produce a well-formed message, RSA encryption alone proves no origin
#
#  new() and reinit() always take the PEM text of the key itself, never a file
#  name -- loading a key from a file is left to the calling code. the text is
#  handed to Crypt::PK::RSA by reference, so it is never taken for a file name
#
#  options are honoured or refused, never silently ignored:
#
#    HASH => 'SHA256'   hash used for OAEP wrapping and for PSS signatures
#
#  OAEP must carry the 32 byte symmetric key, so the key modulus must be at
#  least 32 + 2*hashsize + 2 bytes. PSS signing needs less, so OAEP decides:
#
#    HASH               hash size   min modulus        smallest usual key
#    SHA1                20 bytes    74 bytes ( 592 bits)   1024 bits
#    SHA224              28 bytes    90 bytes ( 720 bits)   1024 bits
#    SHA256 (default)    32 bytes    98 bytes ( 784 bits)   1024 bits
#    SHA3_256            32 bytes    98 bytes ( 784 bits)   1024 bits
#    SHA384              48 bytes   130 bytes (1040 bits)   1536 bits
#    SHA512              64 bytes   162 bytes (1296 bits)   1536 bits
#    SHA3_512            64 bytes   162 bytes (1296 bits)   1536 bits
#
#  a key too small for the chosen hash is refused by reinit(). these are the
#  minimums which work at all, 2048 bits or more is what should be used
#
#  sign()/verify() work on the message itself and are independent of the
#  encrypt/decrypt pair -- signing proves origin, encryption alone does not
#
#  a public key can encrypt() and verify(), both need only the modulus and the
#  public exponent. decrypt() and sign() need the private exponent and boom if
#  the object was given a public key, that is a configuration error and not a
#  data-dependent one, which is what the undef return value means everywhere else
#
##############################################################################
package Data::Tools::Crypto::RSA;
use strict;

use parent 'Data::Tools::Crypto';

use Exception::Sink;
use Crypt::PK::RSA;
use Crypt::Digest;
use Crypt::PRNG qw( random_bytes );
use Data::Tools::Crypto::Symmetric;
use Encode qw( encode_utf8 );
use Data::Tools qw( str_hex str_unhex );
use MIME::Base64;

our $VERSION = '1.53';

my $SKEY_LEN = 32; # symmetric key size, as required by Crypto::Symmetric

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

my %KNOWN_OPT = map { $_ => 1 } qw( HASH );

sub reinit
{
  my $self = shift;
  my $key  = shift;
  my %opt  = @_;

  %$self = (); # clear state

  boom( "key parameter is not defined" ) unless defined $key;
  boom( "key parameter must be PEM text, not a [" . ref( $key ) . "] reference" ) if ref( $key );
  boom( "key parameter cannot be downgraded from UTF-8" ) if utf8::is_utf8( $key ) and ! utf8::downgrade( $key, 1 );

  my @unknown = grep { ! $KNOWN_OPT{ $_ } } keys %opt;
  boom( "unknown option(s) [" . join( ',', sort @unknown ) . "]" ) if @unknown;

  my $hash = $opt{ 'HASH' } || 'SHA256';

  my $hlen = eval { Crypt::Digest::hashsize( $hash ) };
  boom( "invalid or unknown hash [$hash]" ) unless $hlen;

  # passed by reference, so it is always read as key data and never as a file name
  my $rsa = eval { Crypt::PK::RSA->new( \$key ) };
  boom( "invalid or unsupported RSA key" ) unless $rsa;

  # OAEP can carry keysize-2*hashsize-2 bytes and must fit the symmetric key,
  # otherwise every encrypt() would fail later with nothing to explain why
  my $ksize  = $rsa->size();
  my $budget = $ksize - 2 * $hlen - 2;
  boom( "RSA key too small for [$hash], modulus is [$ksize] bytes, "
      . "needs at least [" . ( $SKEY_LEN + 2 * $hlen + 2 ) . "]" ) if $budget < $SKEY_LEN;

  $self->{ 'RSA'     } = $rsa;
  $self->{ 'HASH'    } = $hash;
  $self->{ 'PRIVATE' } = $rsa->is_private() ? 1 : 0;

  1;
}

##############################################################################

sub encrypt
{
  my $self  = shift;
  my $ptext = shift; # plaintext

  boom( "object state is undefined! use reinit() to setup first" ) unless $self->{ 'RSA' };
  boom( "plaintext not defined" ) unless defined( $ptext );

  # fresh symmetric key per message, wrapped with RSA. the payload itself never
  # passes through RSA, so there is no limit on its size
  my $skey = random_bytes( $SKEY_LEN );

  my $wrapped = eval { $self->{ 'RSA' }->encrypt( $skey, 'oaep', $self->{ 'HASH' } ); };
  return undef if $@ or ! defined $wrapped;

  # utf8 handling and authentication are done by Crypto::Symmetric
  my $sym = Data::Tools::Crypto::Symmetric->new( $skey );

  return $wrapped . $sym->encrypt( $ptext );
}

sub decrypt
{
  my $self  = shift;
  my $ctext = shift; # cryptotext

  boom( "object state is undefined! use reinit() to setup first" ) unless $self->{ 'RSA' };
  boom( "cryptotext not defined" ) unless defined( $ctext );
  boom( "cryptotext must be binary, utf8 scalars are not supported" ) if utf8::is_utf8( $ctext );
  boom( "private key required to decrypt, this object holds a public key" ) unless $self->{ 'PRIVATE' };

  # the wrapped key is always exactly the modulus size
  my $wlen = $self->{ 'RSA' }->size();

  return undef if length( $ctext ) <= $wlen;

  my $wrapped = substr( $ctext, 0, $wlen );
     $ctext   = substr( $ctext, $wlen    );

  my $skey = eval { $self->{ 'RSA' }->decrypt( $wrapped, 'oaep', $self->{ 'HASH' } ); };
  return undef if $@ or ! defined $skey or length( $skey ) != $SKEY_LEN;

  my $sym = Data::Tools::Crypto::Symmetric->new( $skey );

  return $sym->decrypt( $ctext );
}

##############################################################################

# signing is over the message bytes plus the same utf8 marker that encrypt()
# uses, so that a character string and its utf8 byte form never share a signature

sub __sign_body
{
  my $ptext = shift;

  return 'u' . encode_utf8( $ptext ) if utf8::is_utf8( $ptext );
  return 'b' . $ptext;
}

sub sign
{
  my $self  = shift;
  my $ptext = shift; # plaintext

  boom( "object state is undefined! use reinit() to setup first" ) unless $self->{ 'RSA' };
  boom( "plaintext not defined" ) unless defined( $ptext );
  boom( "private key required to sign, this object holds a public key" ) unless $self->{ 'PRIVATE' };

  my $sig = eval { $self->{ 'RSA' }->sign_message( __sign_body( $ptext ), $self->{ 'HASH' }, 'pss' ); };
  return undef if $@ or ! defined $sig;

  return $sig;
}

# true when the object holds a private key, so the caller can tell in advance
# whether decrypt() and sign() are available to it

sub is_private
{
  my $self = shift;

  boom( "object state is undefined! use reinit() to setup first" ) unless $self->{ 'RSA' };

  return $self->{ 'PRIVATE' };
}

sub verify
{
  my $self  = shift;
  my $ptext = shift; # plaintext
  my $sig   = shift; # signature, as returned by sign()

  boom( "object state is undefined! use reinit() to setup first" ) unless $self->{ 'RSA' };
  boom( "plaintext not defined" ) unless defined( $ptext );
  boom( "signature not defined"  ) unless defined( $sig   );
  boom( "signature must be binary, utf8 scalars are not supported" ) if utf8::is_utf8( $sig );

  my $res = eval { $self->{ 'RSA' }->verify_message( $sig, __sign_body( $ptext ), $self->{ 'HASH' }, 'pss' ); };
  return 0 if $@ or ! $res;

  return 1;
}

#-----------------------------------------------------------------------------

# encoded signatures. undef is passed through both ways, so a failed sign()
# stays undef and an undefined signature booms in verify() as it does there

sub sign_hex
{
  my $self = shift;

  my $sig = $self->sign( $_[0] );
  return defined $sig ? str_hex( $sig ) : undef;
}

sub verify_hex
{
  my $self = shift;

  return $self->verify( $_[0], defined $_[1] ? str_unhex( $_[1] ) : undef );
}

sub sign_base64
{
  my $self = shift;

  my $sig = $self->sign( $_[0] );
  return defined $sig ? MIME::Base64::encode_base64( $sig, '' ) : undef;
}

sub verify_base64
{
  my $self = shift;

  return $self->verify( $_[0], defined $_[1] ? MIME::Base64::decode_base64( $_[1] ) : undef );
}

sub sign_base64url
{
  my $self = shift;

  my $sig = $self->sign( $_[0] );
  return defined $sig ? MIME::Base64::encode_base64url( $sig ) : undef;
}

sub verify_base64url
{
  my $self = shift;

  return $self->verify( $_[0], defined $_[1] ? MIME::Base64::decode_base64url( $_[1] ) : undef );
}

##############################################################################

=pod


=head1 NAME

Data::Tools::Crypto::RSA - hybrid public key encryption and digital signatures with an RSA key pair

=head1 SYNOPSIS

  use Data::Tools qw( file_text_load );
  use Data::Tools::Crypto::RSA;
  use Exception::Sink;

  # the key is always the PEM text itself, never a file name

  my $pem    = file_text_load( 'private.pem' );
  my $crypto = Data::Tools::Crypto::RSA->new( $pem );

  # --------------------------------------------------------------------------

  # anyone with the public key can encrypt, only the private key can decrypt

  my $ctext = $crypto->encrypt( $ptext );
  my $ptext = $crypto->decrypt( $ctext );

  boom( "data cannot be decrypted" ) unless defined $ptext;

  # --------------------------------------------------------------------------

  # only the private key can sign, anyone with the public key can verify

  my $sig = $crypto->sign( $message );

  boom( "message is not authentic" ) unless $crypto->verify( $message, $sig );

  # the same, with the signature in text-safe encodings

  my $sig_hex  = $crypto->sign_hex( $message );
  my $sig_b64  = $crypto->sign_base64( $message );
  my $sig_b64u = $crypto->sign_base64url( $message );

  boom( "message is not authentic" ) unless $crypto->verify_base64url( $message, $sig_b64u );

  # --------------------------------------------------------------------------

  # a different hash can be selected, it applies to both wrapping and signing

  my $crypto = Data::Tools::Crypto::RSA->new( $pem, HASH => 'SHA512' );

  # --------------------------------------------------------------------------

  # the whole encoding and freeze/thaw API comes from
  # Data::Tools::Crypto, see there for the full list

  my $sealed = $crypto->freeze_base64url( { name => 'test' } );
  my $data   = $crypto->thaw_base64url( $sealed );

  # --------------------------------------------------------------------------

=head1 DESCRIPTION

Data::Tools::Crypto::RSA encrypts with RSA-OAEP and signs with RSA-PSS.

Encryption is hybrid. RSA by itself can only encrypt a few hundred bytes, so
it is not used on the data at all: a fresh symmetric key is generated for each
message, the message is encrypted with Data::Tools::Crypto::Symmetric and only
that key is wrapped with RSA. There is no limit on the size of the data, and
the payload is authenticated exactly as it is there.

=head1 PUBLIC AND PRIVATE KEYS

A private key contains the public key, so an object holding a private key can
do everything. A public key can only do the two public operations:

                      private key    public key
    encrypt()             yes           yes
    verify()              yes           yes
    decrypt()             yes           no
    sign()                yes           no

This is why a service which only sends encrypted data, or only verifies
signatures, should be given the public key alone -- it works exactly the same
and the private key never reaches that host.

Asking a public key object to decrypt() or sign() is a configuration error,
not a data error, and raises an exception saying so.

=head1 SIGNATURES

Encryption does not prove who sent anything. Anyone holding the public key can
produce a well formed message, because that is precisely what the public key
is for. Only sign()/verify() establish origin, and they are independent of the
encrypt/decrypt pair -- use both when both properties are needed.

=head1 METHODS

=head2 new( $pem_text, %options )

Returns a new object. $pem_text is the PEM text of a public or a private key.
It is never taken for a file name, reading a key from a file is left to the
calling code. Options:

  HASH => 'SHA256'   hash for OAEP wrapping and PSS signatures, default SHA256

Unknown options are refused rather than silently ignored, as is a key too
small to be usable -- see KEY SIZE below.

=head2 reinit( $pem_text, %options )

Sets a new key on an existing object. All previous state is cleared first, so
if the key or an option is rejected the object is left without a key and is
not usable until a later reinit() succeeds. Catching the exception and
handling the unusable object is left to the caller.

=head2 encrypt( $plaintext )

Returns the cryptotext, which is always binary. There is no limit on the size
of the plaintext, the cryptotext is the key modulus size plus 29 bytes longer
than the plaintext.

=head2 decrypt( $cryptotext )

Returns the plaintext, or undef if the cryptotext cannot be decrypted, which
covers a wrong key, modified data, truncated data and random input alike.
Raises an exception if the object holds a public key.

=head2 sign( $message )

Returns an RSA-PSS signature, which is always binary and is the key modulus
size. Raises an exception if the object holds a public key.

=head2 verify( $message, $signature )

Returns true if the signature was made over this exact message by the private
key matching this object's key, false otherwise. An unusable or malformed
signature is simply false, it does not raise an exception.

=head2 sign_hex(), sign_base64(), sign_base64url() and their verify pairs

As sign()/verify() but with the signature HEX, BASE64 or URL-safe BASE64
encoded, so it can be stored or passed as plain text. BASE64 is on a single
line with no newlines added. Only the signature is encoded, the message is
signed and verified exactly as with sign()/verify():

  my $sig = $crypto->sign_hex( $message );
  my $ok  = $crypto->verify_hex( $message, $sig );

An encoded signature which does not decode to a valid signature is simply
false, as in verify().

=head2 is_private()

True if the object holds a private key, so the caller can tell in advance
whether decrypt() and sign() are available to it. Like every other method it
raises an exception on an object whose reinit() failed, rather than answering
false.

=head1 KEY SIZE

OAEP can carry keysize minus twice the hash size minus two bytes, and that
must fit the 32 byte symmetric key, so the key modulus must be at least

  32 + 2 * hash size + 2 bytes

PSS signatures need less than that, so the OAEP limit is the one which
decides. The minimum key size for each HASH option:

  HASH               hash size   min modulus            smallest usual key
  SHA1                20 bytes    74 bytes ( 592 bits)   1024 bits
  SHA224              28 bytes    90 bytes ( 720 bits)   1024 bits
  SHA256 (default)    32 bytes    98 bytes ( 784 bits)   1024 bits
  SHA3_256            32 bytes    98 bytes ( 784 bits)   1024 bits
  SHA384              48 bytes   130 bytes (1040 bits)   1536 bits
  SHA512              64 bytes   162 bytes (1296 bits)   1536 bits
  SHA3_512            64 bytes   162 bytes (1296 bits)   1536 bits

So a 1024 bit key works with SHA256 but is refused with SHA384 or SHA512.
A key too small for the chosen hash is refused when it is loaded, rather than
failing on every encrypt() later.

These are the smallest keys which work at all, not a recommendation: 1024 bit
RSA is no longer considered secure, use 2048 bits or more.

=head1 UTF8 HANDLING

encrypt()/decrypt() are transparent, exactly as described in
Data::Tools::Crypto::Symmetric, which does the work.

sign()/verify() cover the same distinction, so a character string and its utf8
byte form do not share a signature. Signatures are always binary, passing a
character string to verify() raises an exception.

=head1 ERRORS

The two kinds of failure are reported differently and never confused:

  * a caller or configuration error raises an exception with boom(), i.e. a
    key given as a reference instead of PEM text, malformed or unsupported
    key material, a key too small, an invalid
    or unknown hash, an unknown option, an undefined argument, a private
    operation on a public key, or any use of an object whose reinit() failed

  * data which simply does not decrypt or verify returns undef from decrypt()
    and false from verify(), which are normal results the caller must check

=head1 DATA FORMAT

  RSA wrapped symmetric key (key modulus size) . Crypto::Symmetric cryptotext

=head1 REQUIRED MODULES

Data::Tools::Crypto::RSA uses:

  * Data::Tools::Crypto
  * Data::Tools::Crypto::Symmetric
  * Crypt::PK::RSA (CryptX)
  * Crypt::Digest (CryptX)
  * Crypt::PRNG (CryptX)
  * Data::Tools
  * Encode
  * Exception::Sink
  * MIME::Base64

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
