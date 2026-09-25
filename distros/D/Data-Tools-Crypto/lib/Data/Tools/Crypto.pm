##############################################################################
#
#  Data::Tools::Crypto perl module, base class
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
package Data::Tools::Crypto;
use strict;

use JSON;
use Data::Tools qw( str_hex str_unhex );
use MIME::Base64;

our $VERSION = '1.53';

##############################################################################

# decrypt() returns undef for data which does not decrypt, thaw must pass that
# on instead of handing undef to decode_json(), which would die

sub __thaw_json
{
  my $json = shift;

  return undef unless defined $json;
  return decode_json( $json );
}

#-----------------------------------------------------------------------------

sub encrypt_hex
{
  my $self = shift;

  return str_hex( $self->encrypt( $_[0] ) );
}

sub decrypt_hex
{
  my $self = shift;

  return $self->decrypt( str_unhex( $_[0] ) );
}

#-----------------------------------------------------------------------------

sub freeze
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return $self->encrypt( encode_json( $_[0] ) );
}

sub thaw
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return __thaw_json( $self->decrypt( $_[0] ) );
}

sub freeze_hex
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return $self->encrypt_hex( encode_json( $_[0] ) );
}

sub thaw_hex
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return __thaw_json( $self->decrypt_hex( $_[0] ) );
}

#-----------------------------------------------------------------------------

sub encrypt_base64
{
  my $self = shift;

  return MIME::Base64::encode_base64( $self->encrypt( $_[0] ), '' );
}

sub decrypt_base64
{
  my $self = shift;

  return $self->decrypt( MIME::Base64::decode_base64( $_[0] ) );
}

sub freeze_base64
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return $self->encrypt_base64( encode_json( $_[0] ) );
}

sub thaw_base64
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return __thaw_json( $self->decrypt_base64( $_[0] ) );
}

#-----------------------------------------------------------------------------

sub encrypt_base64url
{
  my $self = shift;

  return MIME::Base64::encode_base64url( $self->encrypt( $_[0] ) );
}

sub decrypt_base64url
{
  my $self = shift;

  return $self->decrypt( MIME::Base64::decode_base64url( $_[0] ) );
}

sub freeze_base64url
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return $self->encrypt_base64url( encode_json( $_[0] ) );
}

sub thaw_base64url
{
  my $self = shift;

  # reference to any data/scalar/hash/array
  return __thaw_json( $self->decrypt_base64url( $_[0] ) );
}

##############################################################################

=pod


=head1 NAME

Data::Tools::Crypto - authenticated symmetric and hybrid RSA encryption and signatures, one common API

=head1 SYNOPSIS

  # Data::Tools::Crypto is the base class, it is never used on its own,
  # use one of the implementations which inherit it:

  use Data::Tools::Crypto::Symmetric;
  use Data::Tools::Crypto::RSA;

  my $crypto = Data::Tools::Crypto::Symmetric->new( $key );

  # --------------------------------------------------------------------------

  # raw binary data in, raw binary data out

  my $ctext = $crypto->encrypt( $ptext );
  my $ptext = $crypto->decrypt( $ctext );

  # --------------------------------------------------------------------------

  # the same, in text-safe encodings

  my $hex   = $crypto->encrypt_hex( $ptext );
  my $ptext = $crypto->decrypt_hex( $hex   );

  my $b64   = $crypto->encrypt_base64( $ptext );
  my $ptext = $crypto->decrypt_base64( $b64   );

  my $b64u  = $crypto->encrypt_base64url( $ptext );
  my $ptext = $crypto->decrypt_base64url( $b64u  );

  # --------------------------------------------------------------------------

  # any perl data structure, JSON-serialised and encrypted in one step

  my $data  = { name => 'test', list => [ 1, 2, 3 ] };

  my $sealed = $crypto->freeze( $data   );
  my $data   = $crypto->thaw(   $sealed );

  my $sealed = $crypto->freeze_hex(       $data   );
  my $sealed = $crypto->freeze_base64(    $data   );
  my $sealed = $crypto->freeze_base64url( $data   );

  # --------------------------------------------------------------------------

=head1 DESCRIPTION

Data::Tools::Crypto provides authenticated encryption, hybrid public key
encryption and digital signatures, with a single common API:

  * Data::Tools::Crypto::Symmetric -- shared secret key, ChaCha20-Poly1305
  * Data::Tools::Crypto::RSA       -- public/private key pair, hybrid, signatures

This module is the base class of both. It implements no encryption of its own,
it defines the API which every implementation offers and provides the encoding
and serialisation wrappers on top of the encrypt() and decrypt() methods that
the inheriting module must provide.

Errors behave exactly as in the inheriting module, since every method here
goes through its encrypt() or decrypt(): caller errors raise an exception,
and data which does not decrypt makes decrypt_*() and thaw*() return undef.

The base class is not usable by itself and has nothing to export, always use
one of the implementations listed above.

freeze/thaw use JSON as a safer option than Storable, so only plain data can
be carried: hashes, arrays, scalars and numbers. Blessed objects, code
references and circular structures cannot be serialised.

=head1 METHODS

=head2 encrypt( $plaintext ), decrypt( $cryptotext )

Implemented by the inheriting module, not by the base class. All the methods below are
built on top of these two.

=head2 encrypt_hex( $plaintext ), decrypt_hex( $cryptotext )

As encrypt()/decrypt() but the cryptotext is HEX encoded, so it is plain text
and safe to store or pass anywhere a binary string would not survive.

=head2 encrypt_base64( $plaintext ), decrypt_base64( $cryptotext )

As encrypt()/decrypt() but the cryptotext is BASE64 encoded, on a single line
with no newlines added.

=head2 encrypt_base64url( $plaintext ), decrypt_base64url( $cryptotext )

As encrypt_base64() but using the URL and filename safe BASE64 alphabet, so
the result can be used in a URL or a file name without further escaping.

=head2 freeze( $data_ref ), thaw( $cryptotext )

freeze() serialises any plain perl data structure to JSON and encrypts it.
thaw() reverses this and returns the data structure back, or undef if the
cryptotext cannot be decrypted, exactly as decrypt() does.

=head2 freeze_hex(), freeze_base64(), freeze_base64url() and their thaw pairs

As freeze()/thaw() but with the cryptotext encoded as described above:

  my $sealed = $crypto->freeze_hex( $data_ref );
  my $data   = $crypto->thaw_hex(   $sealed   );

=head1 REQUIRED MODULES

Data::Tools::Crypto uses:

  * Data::Tools
  * JSON
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
