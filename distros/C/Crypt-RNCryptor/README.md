[![Build Status](https://travis-ci.org/s-shin/p5-Crypt-RNCryptor.svg?branch=master)](https://travis-ci.org/s-shin/p5-Crypt-RNCryptor)
# NAME

Crypt::RNCryptor - Perl implementation of [RNCryptor](https://github.com/RNCryptor/RNCryptor)

# SYNOPSIS

    use Crypt::RNCryptor;

    # generate password-based encryptor
    $cryptor = Crypt::RNCryptor->new(
        password => 'secret password',
    );

    # generate key-based encryptor
    $cryptor = Crypt::RNCryptor->new(
        encryption_key => '',
        hmac_key => '',
    );

    # encrypt
    $ciphertext = $cryptor->encrypt('plaintext');

    # decrypt
    $plaintext = $cryptor->decrypt($ciphertext);

# DESCRIPTION

Crypt::RNCryptor is a Perl implementation of RNCryptor,
which is one of data format for AES-256 (CBC mode) encryption.

Crypt::RNCryptor class is the base of Crypt::RNCryptor::V\* class
and declare some abstract methods.

# METHODS

## CLASS METHODS

- my $cryptor = Crypt::RNCryptor->new(%opts);

    Create a cryptor instance.

        %opts = (
            # RNCryptor version. Currently support only version 3)
            version => $Crypt::RNCryptor::DefaultRNCryptorVersion,
            # See Crypt::RNCryptor::V*
            %version_dependent_opts
        );

## INSTANCE METHODS

- $ciphertext = $cryptor->encrypt($plaintext, %version\_dependent\_opts)

    Encrypt plaintext with options.

- $plaintext = $cryptor->decrypt($ciphertext, %version\_dependent\_opts)

    Decrypt ciphertext with options.

## MODULE VARIABLES

- $Crypt::RNCryptor::DefaultRNCryptorVersion = '3'

    Default RNCryptor version.

- @Crypt::RNCryptor::DefaultRNCryptorVersion

    List of supporting RNCryptor versions.

# LICENSE

Copyright (C) Shintaro Seki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shintaro Seki <s2pch.luck@gmail.com>
