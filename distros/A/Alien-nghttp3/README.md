# Alien::nghttp3

[![CI](https://github.com/haxmeister/perl-Alien-nghttp3/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Alien-nghttp3/actions/workflows/test.yml)
[![Perl](https://img.shields.io/badge/perl-5.20%2B-blue.svg)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![nghttp3](https://img.shields.io/badge/nghttp3-1.18.0-blue.svg)](https://github.com/ngtcp2/nghttp3)

Alien::nghttp3 makes the native libnghttp3 library available to Perl modules.

nghttp3 is a C library for HTTP/3 and QPACK. It does not provide QUIC
transport.

## Installation

Install it like a normal Perl module:

    cpanm Alien::nghttp3

Alien::nghttp3 first looks for libnghttp3 1.18.0 or newer on the system.

If a suitable system library is found, it is used.

If not, Alien::nghttp3 builds the vendored nghttp3 1.18.0 source included in
this distribution. The fallback build does not download nghttp3 from the
network.

## Using Alien::nghttp3

Perl modules that need libnghttp3 can use the normal Alien interface:

    use Alien::nghttp3;

    my $cflags  = Alien::nghttp3->cflags;
    my $libs    = Alien::nghttp3->libs;
    my $version = Alien::nghttp3->version;

These values can be used when compiling and linking XS code.

## Scope

Alien::nghttp3 only supplies libnghttp3.

It does not provide a Perl HTTP/3 API, QUIC transport, TLS, an event loop, or
a web framework.

It does not depend on Net::QUIC, Linux::Event, ngtcp2, or any other QUIC
implementation.

This keeps the distribution usable by any Perl project that needs libnghttp3.

## Requirements

Alien::nghttp3 requires:

- Perl 5.20 or newer
- Alien::Build 2.84 or newer
- a C11 compiler when the vendored library must be built

The fallback build uses CMake and builds only the static libnghttp3 library.

## Vendored source

The fallback source is nghttp3 1.18.0.

The exact upstream source and sfparse revision are recorded in
[vendored source notes](vendor/README.md).

## Development

    perl Makefile.PL
    make
    make test

See [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## License

Alien::nghttp3 is released under the MIT License.

The vendored nghttp3 and sfparse sources are also MIT licensed.
