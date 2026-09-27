# Contributing to Alien::ngtcp2

Contributions are welcome through the GitHub repository:

https://github.com/haxmeister/perl-Alien-ngtcp2

## Reporting bugs

Please open an issue and include enough information to reproduce the problem,
including:

- operating system
- Perl version
- Alien::Build version
- compiler and build tool versions when relevant
- whether a system libngtcp2 or the bundled source build was used
- complete error output

For security issues, follow SECURITY.md instead of opening a public issue.

## Development

Alien::ngtcp2 requires Perl 5.20 or newer and Alien::Build 2.84 or newer.

A normal development build is:

    perl Makefile.PL
    make
    make test

To force the bundled ngtcp2 source build:

    ALIEN_INSTALL_TYPE=share perl Makefile.PL
    make
    make test

To require a system libngtcp2 installation:

    ALIEN_INSTALL_TYPE=system perl Makefile.PL
    make
    make test

Before submitting a pull request, make sure the test suite passes. Changes to
the native build path should be kept portable across the supported Linux,
macOS, and Windows configurations.

## Scope

Alien::ngtcp2 is intentionally limited to locating or building the core
libngtcp2 library. Perl QUIC APIs, HTTP/3, TLS integration, and event-loop
integration belong in other distributions.
