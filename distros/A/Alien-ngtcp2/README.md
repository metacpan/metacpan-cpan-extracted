# Alien::ngtcp2

[![CI](https://github.com/haxmeister/perl-Alien-ngtcp2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Alien-ngtcp2/actions/workflows/test.yml)
[![Perl](https://img.shields.io/badge/perl-5.20%2B-blue.svg)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![ngtcp2](https://img.shields.io/badge/ngtcp2-1.25.0-blue.svg)](https://github.com/ngtcp2/ngtcp2)

Alien::ngtcp2 builds the native libraries needed by Perl QUIC modules.

## What gets built

Alien::ngtcp2 provides one tested native stack:

    ngtcp2 1.25.0
        |
        +-- libngtcp2_crypto_picotls
                |
                +-- Picotls
                        |
                        +-- OpenSSL crypto

ngtcp2 handles QUIC.

Picotls handles TLS 1.3.

OpenSSL supplies cryptography and X.509 certificate handling underneath
Picotls. Net::QUIC does not use OpenSSL's QUIC TLS API.

The bundled Picotls source is pinned to commit:

    f07f1c8c68b237f1468bc1f1fe1b68aba3ff23b4

That is the Picotls revision documented for ngtcp2 1.25.0.

Alien::ngtcp2 builds this pair itself instead of reusing an arbitrary system
ngtcp2 TLS helper. A system helper does not tell us which Picotls revision it
was built against.

## OpenSSL

On Unix-like systems, Alien::ngtcp2 uses a system OpenSSL 1.1.1 or newer when
one is available.

If no suitable OpenSSL development installation is available,
Alien::OpenSSL can provide one.

On Windows, Alien::ngtcp2 uses the OpenSSL that belongs to the active Perl and
compiler toolchain. It does not silently install a second TLS stack.

Historical Strawberry Perl 5.28 contains OpenSSL 1.1.0j and is too old.
Strawberry Perl 5.30 and newer meet the required baseline.

## Using it from another Perl distribution

The core ngtcp2 compiler and linker flags are:

    use Alien::ngtcp2;

    my $cflags = Alien::ngtcp2->cflags;
    my $libs   = Alien::ngtcp2->libs;

The TLS helper flags are:

    my $crypto_cflags = Alien::ngtcp2->crypto_cflags;
    my $crypto_libs   = Alien::ngtcp2->crypto_libs;

The compatibility methods remain available:

    Alien::ngtcp2->crypto_backend;  # picotls
    Alien::ngtcp2->crypto_package;  # libngtcp2_crypto_picotls

A normal Net::QUIC user should not need to call these methods directly.

## Compatibility

Alien::ngtcp2 requires:

- Perl 5.20 or newer
- Alien::Build 2.84 or newer
- OpenSSL 1.1.1 or newer

The bundled ngtcp2 source is version 1.25.0.

## Development

    perl Makefile.PL
    make
    make test

See CONTRIBUTING.md for more development information.

## License

Alien::ngtcp2 is MIT licensed.

The bundled Picotls source subset is also MIT licensed and keeps its upstream
copyright and license notices.
