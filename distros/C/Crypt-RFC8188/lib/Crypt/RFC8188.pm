package Crypt::RFC8188;
use strict;
use warnings;
use MIME::Base64 qw(encode_base64url decode_base64url);
use Crypt::PK::ECC;
use Math::BigInt;
use Encode qw(encode decode);
use Crypt::KeyDerivation qw(hkdf hkdf_extract hkdf_expand);
use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);
use Exporter qw(import);
use Crypt::PRNG qw(random_bytes);

our $VERSION = "0.04";
our @EXPORT_OK = qw(ece_encrypt_aes128gcm ece_decrypt_aes128gcm derive_key);

my $MAX_RECORD_SIZE = (2 ** 31) - 1;

# $dh will always be public key data - decode_base64url if necessary
sub derive_key {
  my ($mode, $salt, $key, $private_key, $dh, $auth_secret) = @_;
  die "Salt must be 16 octets\n" unless $salt and length $salt == 16;
  my ($context, $secret) = ("");
  if ($dh) {
    die "DH requires a private_key\n" unless $private_key;
    my $pubkey = Crypt::PK::ECC->new->import_key_raw($dh, 'P-256'); 
    my $encoded = $private_key->export_key_raw('public');
    my ($sender_pub_key, $receiver_pub_key) = ($mode eq "encrypt")
      ? ($encoded, $dh) : ($dh, $encoded);
    $context = "WebPush: info\x00" . $receiver_pub_key . $sender_pub_key;
    $secret = $private_key->shared_secret($pubkey);
  } else {
    $secret = $key;
  }
  die "Unable to determine the secret\n" unless $secret;
  my $keyinfo = "Content-Encoding: aes128gcm\x00";
  my $nonceinfo = "Content-Encoding: nonce\x00";
  # Only mix the authentication secret when using DH for aes128gcm
  $auth_secret = undef if !$dh;
  if ($auth_secret) {
    $secret = hkdf $secret, $auth_secret, 'SHA256', 32, $context;
  }
  (
    hkdf($secret, $salt, 'SHA256', 16, $keyinfo),
    hkdf($secret, $salt, 'SHA256', 12, $nonceinfo),
  );
}

sub ece_encrypt_aes128gcm {
  my (
    $content, $salt, $key, $private_key, $dh, $auth_secret, $keyid, $rs,
  ) = @_;
  $salt ||= random_bytes(16);
  $rs ||= 4096;
  die "Too much content\n" if $rs > $MAX_RECORD_SIZE;
  my ($key_, $nonce_) = derive_key(
    'encrypt', $salt, $key, $private_key, $dh, $auth_secret,
  );
  my $overhead = 17;
  die "Record size too small\n" if $rs <= $overhead;
  my $end = length $content;
  my $chunk_size = $rs - $overhead;
  my $result = "";
  my $counter = 0;
  my $nonce_bigint = Math::BigInt->from_bytes($nonce_);
  # the extra one on the loop ensures that we produce a padding only
  # record if the data length is an exact multiple of the chunk size
  for (my $i = 0; $i <= $end; $i += $chunk_size) {
    my $iv = ($nonce_bigint ^ $counter)->as_bytes;
    my ($data, $tag) = gcm_encrypt_authenticate 'AES', $key_, $iv, '',
      substr($content, $i, $chunk_size) .
        ((($i + $chunk_size) >= $end) ? "\x02" : "\x01")
      ;
    $result .= $data . $tag;
    $counter++;
  }
  if (!$keyid and $private_key) {
    $keyid = $private_key->export_key_raw('public');
  } else {
    $keyid = encode('UTF-8', $keyid || '', Encode::FB_CROAK | Encode::LEAVE_SRC);
  }
  die "keyid is too long\n" if length($keyid) > 255;
  $salt . pack('L> C', $rs, length $keyid) . $keyid . $result;
}

sub ece_decrypt_aes128gcm {
  my (
    # no salt, keyid, rs as encoded in header
    $content, $key, $private_key, $dh, $auth_secret,
  ) = @_;
  my $id_len = unpack 'C', substr $content, 20, 1;
  my $salt = substr $content, 0, 16;
  my $rs = unpack 'L>', substr $content, 16, 4;
  my $overhead = 17;
  die "Record size too small\n" if $rs <= $overhead;
  my $keyid = substr $content, 21, $id_len;
  $content = substr $content, 21 + $id_len;
  if ($private_key and !$dh) {
    $dh = $keyid;
  } else {
    $keyid = decode('UTF-8', $keyid || '', Encode::FB_CROAK | Encode::LEAVE_SRC);
  }
  my ($key_, $nonce_) = derive_key(
    'decrypt', $salt, $key, $private_key, $dh, $auth_secret,
  );
  my $chunk_size = $rs;
  my $result = "";
  my $counter = 0;
  my $end = length $content;
  my $nonce_bigint = Math::BigInt->from_bytes($nonce_);
  for (my $i = 0; $i < $end; $i += $chunk_size) {
    my $iv = ($nonce_bigint ^ $counter)->as_bytes;
    my $bit = substr $content, $i, $chunk_size;
    my $ciphertext = substr $bit, 0, length($bit) - 16;
    my $tag = substr $bit, -16;
    my $data = gcm_decrypt_verify 'AES', $key_, $iv, '', $ciphertext, $tag;
    die "Decryption error\n" unless defined $data;
    my $last = ($i + $chunk_size) >= $end;
    $data =~ s/\x00*\z//;
    die "all zero record plaintext\n" if !length $data;
    my $last_byte = ord substr $data, -1, 1, '';
    die "record delimiter($last_byte) != 1\n" if !$last and $last_byte != 1;
    die "last record delimiter($last_byte) != 2\n" if $last and $last_byte != 2;
    $result .= $data;
    $counter++;
  }
  $result;
}

=encoding utf-8

=head1 NAME

Crypt::RFC8188 - Implement RFC 8188 HTTP Encrypted Content Encoding

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/Crypt-RFC8188.svg?branch=master)](https://travis-ci.org/mohawk2/Crypt-RFC8188) |

[![CPAN version](https://badge.fury.io/pl/Crypt-RFC8188.svg)](https://metacpan.org/pod/Crypt-RFC8188) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/Crypt-RFC8188/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/Crypt-RFC8188?branch=master)

=end markdown

=head1 SYNOPSIS

  use Crypt::RFC8188 qw(ece_encrypt_aes128gcm ece_decrypt_aes128gcm);
  my $ciphertext = ece_encrypt_aes128gcm(
    $plaintext, $salt, $key, $private_key, $dh, $auth_secret, $keyid, $rs,
  );
  my $plaintext = ece_decrypt_aes128gcm(
    # no salt, keyid, rs as encoded in header
    $ciphertext, $key, $private_key, $dh, $auth_secret,
  );

=head1 DESCRIPTION

This module implements RFC 8188, the HTTP Encrypted Content Encoding
standard. Among other things, this is used by Web Push (RFC 8291).

It implements only the C<aes128gcm> (Advanced Encryption Standard
128-bit Galois/Counter Mode) encryption, not the previous draft standards
envisaged for Web Push. It implements neither C<aesgcm> nor C<aesgcm128>.

=head1 FUNCTIONS

Exportable (not by default) functions:

=head2 ece_encrypt_aes128gcm

Arguments:

=head3 $plaintext

The plain text.

=head3 $salt

A randomly-generated 16-octet sequence. If not provided, one will be
generated. This is still useful as the salt is included in the ciphertext.

=head3 $key

A secret key to be exchanged by other means.

=head3 $private_key

The private key of a L<Crypt::PK::ECC> Prime 256 ECDSA key.

=head3 $dh

If the private key above is provided, this is the recipient's public
key of an Prime 256 ECDSA key.

=head3 $auth_secret

An authentication secret.

=head3 $keyid

If provided, the ID of a key to be looked up by other means.

=head3 $rs

The record size for encrypted blocks. Must be at least 18, which would
be very inefficient as the overhead is 17 bytes. Defaults to 4096.

=head2 ece_decrypt_aes128gcm

=head3 $ciphertext

The plain text.

=head3 $key

=head3 $private_key

=head3 $dh

=head3 $auth_secret

All as above. C<$salt>, C<$keyid>, C<$rs> are not given since they are
encoded in the ciphertext.

=head1 SEE ALSO

L<https://github.com/web-push-libs/encrypted-content-encoding>

RFC 8188 - Encrypted Content-Encoding for HTTP (using C<aes128gcm>).

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
