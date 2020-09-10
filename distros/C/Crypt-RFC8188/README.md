# NAME

Crypt::RFC8188 - Implement RFC 8188 HTTP Encrypted Content Encoding

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/Crypt-RFC8188.svg?branch=master)](https://travis-ci.org/mohawk2/Crypt-RFC8188) |

[![CPAN version](https://badge.fury.io/pl/Crypt-RFC8188.svg)](https://metacpan.org/pod/Crypt-RFC8188) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/Crypt-RFC8188/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/Crypt-RFC8188?branch=master)

# SYNOPSIS

    use Crypt::RFC8188 qw(ece_encrypt_aes128gcm ece_decrypt_aes128gcm);
    my $ciphertext = ece_encrypt_aes128gcm(
      $plaintext, $salt, $key, $private_key, $dh, $auth_secret, $keyid, $rs,
    );
    my $plaintext = ece_decrypt_aes128gcm(
      # no salt, keyid, rs as encoded in header
      $ciphertext, $key, $private_key, $dh, $auth_secret,
    );

# DESCRIPTION

This module implements RFC 8188, the HTTP Encrypted Content Encoding
standard. Among other things, this is used by Web Push (RFC 8291).

It implements only the `aes128gcm` (Advanced Encryption Standard
128-bit Galois/Counter Mode) encryption, not the previous draft standards
envisaged for Web Push. It implements neither `aesgcm` nor `aesgcm128`.

# FUNCTIONS

Exportable (not by default) functions:

## ece\_encrypt\_aes128gcm

Arguments:

### $plaintext

The plain text.

### $salt

A randomly-generated 16-octet sequence. If not provided, one will be
generated. This is still useful as the salt is included in the ciphertext.

### $key

A secret key to be exchanged by other means.

### $private\_key

The private key of a [Crypt::PK::ECC](https://metacpan.org/pod/Crypt%3A%3APK%3A%3AECC) Prime 256 ECDSA key.

### $dh

If the private key above is provided, this is the recipient's public
key of an Prime 256 ECDSA key.

### $auth\_secret

An authentication secret.

### $keyid

If provided, the ID of a key to be looked up by other means.

### $rs

The record size for encrypted blocks. Must be at least 18, which would
be very inefficient as the overhead is 17 bytes. Defaults to 4096.

## ece\_decrypt\_aes128gcm

### $ciphertext

The plain text.

### $key

### $private\_key

### $dh

### $auth\_secret

All as above. `$salt`, `$keyid`, `$rs` are not given since they are
encoded in the ciphertext.

# SEE ALSO

[https://github.com/web-push-libs/encrypted-content-encoding](https://github.com/web-push-libs/encrypted-content-encoding)

RFC 8188 - Encrypted Content-Encoding for HTTP (using `aes128gcm`).

# AUTHOR

Ed J, `<etj at cpan.org>`

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
