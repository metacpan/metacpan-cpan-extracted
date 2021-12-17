package Crypt::Perl;

use strict;
use warnings;

our $VERSION = '0.37';

=encoding utf-8

=head1 NAME

Crypt::Perl - Cryptography in pure Perl

=head1 DESCRIPTION

=begin html

<a href='https://coveralls.io/github/FGasper/p5-Crypt-Perl?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Crypt-Perl/badge.svg?branch=master' alt='Coverage Status' /></a>

=end html

Just as it sounds: cryptography with no non-core XS dependencies!
This is useful if you don’t have access to
other tools that do this work like L<OpenSSL|http://openssl.org>, L<CryptX>,
etc. Of course, if you do have access to one of those tools, they may suit
your purpose better.

See submodules for usage examples of:

=over

=item * Key generation

=item * Key parsing

=item * Signing & verification

=item * Encryption & decryption

=item * Import (L<Crypt::Perl::PK>) from & export to L<JSON Web Key|https://tools.ietf.org/html/rfc7517> format

=item * L<JWK thumbprints|https://tools.ietf.org/html/rfc7638>

=item * Certificate Signing Request (PKCS #10) generation (L<Crypt::Perl::PKCS10>)

=item * SSL/TLS certificate (X.509) generation (L<Crypt::Perl::X509v3>), including
a broad variety of extensions

=back

=head1 SUPPORTED PUBLIC KEY ALGORITHMS

=over

=item * L<RSA|Crypt::Perl::RSA>

=item * L<ECDSA|Crypt::Perl::ECDSA>

=item * L<Ed25519|Crypt::Perl::Ed25519>

=back

=head1 SECURITY

Random number generation here comes from L<Bytes::Random::Secure::Tiny>.
See that module’s documentation for details of its reliability.

An extensive test suite is included that compares against
L<OpenSSL|https://openssl.org> and
L<LibTomCrypt|https://www.libtom.net/LibTomCrypt/> (i.e., L<CryptX>),
when available.

That said: B<NO GUARANTEES!!!> It’s best to restrict use of this library
to contexts where more “visible” cryptography libraries like the ones
mentioned elsewhere here are unavailable.

And of course, L<OpenSSL has not been trouble-free, either …|https://www.openssl.org/news/vulnerabilities.html>

Caveat emptor.

=head1 HISTORICAL VULNERABILITIES

=over

=item * L<CVE-2020-13895|https://nvd.nist.gov/vuln/detail/CVE-2020-13895>

=item * L<CVE-2020-17478|https://nvd.nist.gov/vuln/detail/CVE-2020-17478>

=back

=head1 SPEED

RSA key generation is slow—too slow, probably, unless you have
L<Math::BigInt::GMP> or L<Math::BigInt::Pari> (either of which requires XS).
It’s one application where pure-Perl cryptography just doesn’t seem
feasible. :-( Everything else, though, including all ECDSA and Ed25519
operations, should be fine even in pure Perl.

Note that this distribution’s test suite is also pretty slow without an
XS backend.

=head1 TODO

There are TODO items listed in the submodules; the following are general
to the entire distribution.

=over

=item * Document the exception system so that applications can use it.

=item * Add more tests, e.g., against L<CryptX>.

=item * Some formal security audit would be nice.

=item * Make it faster :)

=back

=head1 ACKNOWLEDGEMENTS

Much of the logic here comes from Kenji Urushima’s L<jsrsasign|https://github.com/kjur/jsrsasign>.

Most of the tests depend on the near-ubiquitous L<OpenSSL|http://openssl.org>,
without which the Internet would be a very, very different reality from
what we know!

The Ed25519 logic is ported from L<forge.js|https://github.com/digitalbazaar/forge/blob/master/lib/ed25519.js>.

Deterministic ECDSA logic derived in part from
L<python-ecdsa|https://github.com/ecdsa/python-ecdsa>.

Other parts are ported from L<LibTomCrypt|http://www.libtom.net>.

Special thanks to Antonio de la Piedra for having submitted
multiple high-quality, in-depth bug reports.

=head1 LICENSE

This library is licensed under the same license as Perl.

=head1 AUTHOR

Felipe Gasper (FELIPE)

=cut

1;
