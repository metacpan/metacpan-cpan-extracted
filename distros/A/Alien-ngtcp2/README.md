# Alien::ngtcp2

[![CI](https://github.com/haxmeister/perl-Alien-ngtcp2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Alien-ngtcp2/actions/workflows/test.yml)
[![Version](https://img.shields.io/badge/version-0.01-blue.svg)](https://github.com/haxmeister/perl-Alien-ngtcp2)
[![CPANTS lint](https://img.shields.io/badge/CPANTS%20lint-passing-brightgreen.svg)](https://cpants.cpanauthors.org/)
[![Disttest](https://img.shields.io/badge/disttest-passing-brightgreen.svg)](https://github.com/haxmeister/perl-Alien-ngtcp2/actions/workflows/test.yml)
[![CPAN Testers](https://img.shields.io/badge/CPAN%20Testers-pending-lightgrey.svg)](https://www.cpantesters.org/distro/A/Alien-ngtcp2.html)
[![Perl](https://img.shields.io/badge/perl-5.20%2B-blue.svg)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/haxmeister/perl-Alien-ngtcp2.svg)](https://github.com/haxmeister/perl-Alien-ngtcp2/commits/main)
[![Issues](https://img.shields.io/github/issues/haxmeister/perl-Alien-ngtcp2.svg)](https://github.com/haxmeister/perl-Alien-ngtcp2/issues)
[![Stars](https://img.shields.io/github/stars/haxmeister/perl-Alien-ngtcp2.svg)](https://github.com/haxmeister/perl-Alien-ngtcp2/stargazers)
[![Forks](https://img.shields.io/github/forks/haxmeister/perl-Alien-ngtcp2.svg)](https://github.com/haxmeister/perl-Alien-ngtcp2/network/members)
[![Platforms](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue.svg)](#compatibility)
[![ngtcp2](https://img.shields.io/badge/ngtcp2-1.25.0%2B-blue.svg)](https://github.com/ngtcp2/ngtcp2)
[![Alien::Build](https://img.shields.io/badge/Alien%3A%3ABuild-2.84%2B-blue.svg)](https://metacpan.org/pod/Alien::Build)

Alien::ngtcp2 finds or builds the native ngtcp2 QUIC transport library for
Perl distributions.

It is deliberately independent of any Perl QUIC implementation, HTTP/3
implementation, TLS backend, or event loop.

## Compatibility

Alien::ngtcp2 targets Perl 5.20 and newer and requires Alien::Build 2.84 or
newer.

The source-build path is tested across a broad Perl version range on Linux,
macOS, and Windows, including Strawberry Perl. The bundled native library
requires a C11-capable compiler.

## Behavior

If pkg-config can find libngtcp2 1.25.0 or newer, Alien::ngtcp2 uses that
system installation.

Otherwise it downloads ngtcp2 1.25.0 and builds a private static copy of the
core libngtcp2 library.

The fallback build does not include ngtcp2 crypto helper libraries or the
example applications.

## Use from another Perl distribution

Consumers use the normal Alien::Base interface:

    use Alien::ngtcp2;

    my $cflags = Alien::ngtcp2->cflags;
    my $libs   = Alien::ngtcp2->libs;

For XS distributions, the usual Alien::Base / Alien::Build integration can use
those flags during compilation and linking.

## Development

    perl Makefile.PL
    make
    make test

Set ALIEN_INSTALL_TYPE=share to force the bundled source-build path when
testing it:

    ALIEN_INSTALL_TYPE=share perl Makefile.PL
    make
    make test

Set ALIEN_INSTALL_TYPE=system to require a suitable system installation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

Security issues should be reported according to [SECURITY.md](SECURITY.md).

## License

MIT
