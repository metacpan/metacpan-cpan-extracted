# Contributing to Alien::ngtcp2

Contributions are welcome through the GitHub repository:

https://github.com/haxmeister/perl-Alien-ngtcp2

## Reporting bugs

Please open an issue and include enough information to reproduce the problem.

Useful details are:

- operating system
- Perl version
- Alien::Build version
- compiler version when relevant
- the output from `perl Makefile.PL`
- the output from `make` or `make test`
- the output from `pkgconf --modversion openssl` when pkgconf is available

For security issues, follow SECURITY.md instead of opening a public issue.

## Development

Alien::ngtcp2 requires Perl 5.20 or newer and Alien::Build 2.84 or newer.

A normal development build is:

    perl Makefile.PL
    make
    make test

Alien::ngtcp2 deliberately builds its own ngtcp2 1.25.0 and pinned Picotls
pair. There is no TLS-backend selection switch.

On Unix-like systems it reuses a suitable system OpenSSL when possible.
Alien::OpenSSL supplies the fallback when needed.

On Windows it uses the OpenSSL development tree associated with the active
Perl/compiler toolchain.

Before submitting a pull request, make sure the test suite passes.

Changes to the native build path should keep working on the supported Linux,
macOS, and Windows configurations.

## Scope

Alien::ngtcp2 supplies the native pieces needed by a Perl QUIC library:

- libngtcp2
- libngtcp2_crypto_picotls
- the pinned Picotls TLS core and OpenSSL binding

It does not provide a Perl QUIC connection API, HTTP/3, UDP socket handling, or
an event loop. Those belong in higher-level distributions such as Net::QUIC.
