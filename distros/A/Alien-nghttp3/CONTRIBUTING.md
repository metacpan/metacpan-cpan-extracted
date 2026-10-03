# Contributing to Alien::nghttp3

Contributions are welcome at:

https://github.com/haxmeister/perl-Alien-nghttp3

## Reporting bugs

Please open a GitHub issue and include:

- your operating system
- your Perl version
- your Alien::Build version
- your compiler version, if the native build failed
- the output from `perl Makefile.PL`
- the output from `make` or `make test`

If you have a system libnghttp3, the output from this can also help:

    pkgconf --modversion libnghttp3

For security problems, please follow SECURITY.md instead of opening a public
issue.

## Development

A normal development build is:

    perl Makefile.PL
    make
    make test

Alien::nghttp3 uses a system libnghttp3 1.18.0 or newer when one is available.
Otherwise it builds the vendored nghttp3 1.18.0 source with CMake.

The fallback build does not download nghttp3 from the network.

Before submitting a pull request, make sure the test suite passes.

## Project scope

Alien::nghttp3 supplies libnghttp3 to Perl modules.

Please keep it independent of Net::QUIC, Linux::Event, ngtcp2, TLS
implementations, event loops, and Perl HTTP frameworks.

HTTP/3 or QUIC integration belongs in a higher-level distribution.
