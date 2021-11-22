# NAME

Crypt::Perl - Cryptography in pure Perl

# DESCRIPTION

<div>
    <a href='https://coveralls.io/github/FGasper/p5-Crypt-Perl?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Crypt-Perl/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

Just as it sounds: cryptography with no non-core XS dependencies!
This is useful if you don’t have access to
other tools that do this work like [OpenSSL](http://openssl.org), [CryptX](https://metacpan.org/pod/CryptX),
etc. Of course, if you do have access to one of those tools, they may suit
your purpose better.

See submodules for usage examples of:

- Key generation
- Key parsing
- Signing & verification
- Encryption & decryption
- Import ([Crypt::Perl::PK](https://metacpan.org/pod/Crypt%3A%3APerl%3A%3APK)) from & export to [JSON Web Key](https://tools.ietf.org/html/rfc7517) format
- [JWK thumbprints](https://tools.ietf.org/html/rfc7638)
- Certificate Signing Request (PKCS #10) generation ([Crypt::Perl::PKCS10](https://metacpan.org/pod/Crypt%3A%3APerl%3A%3APKCS10))
- SSL/TLS certificate (X.509) generation ([Crypt::Perl::X509v3](https://metacpan.org/pod/Crypt%3A%3APerl%3A%3AX509v3)), including
a broad variety of extensions

# SUPPORTED PUBLIC KEY ALGORITHMS

- [RSA](https://metacpan.org/pod/Crypt%3A%3APerl%3A%3ARSA)
- [ECDSA](https://metacpan.org/pod/Crypt%3A%3APerl%3A%3AECDSA)
- [Ed25519](https://metacpan.org/pod/Crypt%3A%3APerl%3A%3AEd25519)

# SECURITY

Random number generation here comes from [Bytes::Random::Secure::Tiny](https://metacpan.org/pod/Bytes%3A%3ARandom%3A%3ASecure%3A%3ATiny).
See that module’s documentation for details of its reliability.

An extensive test suite is included that compares against
[OpenSSL](https://openssl.org) and
[LibTomCrypt](https://www.libtom.net/LibTomCrypt/) (i.e., [CryptX](https://metacpan.org/pod/CryptX)),
when available.

That said: **NO GUARANTEES!!!** It’s best to restrict use of this library
to contexts where more “visible” cryptography libraries like the ones
mentioned elsewhere here are unavailable.

And of course, [OpenSSL has not been trouble-free, either …](https://www.openssl.org/news/vulnerabilities.html)

Caveat emptor.

# HISTORICAL VULNERABILITIES

- [CVE-2020-13895](https://nvd.nist.gov/vuln/detail/CVE-2020-13895)
- [CVE-2020-17478](https://nvd.nist.gov/vuln/detail/CVE-2020-17478)

# SPEED

RSA key generation is slow—too slow, probably, unless you have
[Math::BigInt::GMP](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3AGMP) or [Math::BigInt::Pari](https://metacpan.org/pod/Math%3A%3ABigInt%3A%3APari) (either of which requires XS).
It’s one application where pure-Perl cryptography just doesn’t seem
feasible. :-( Everything else, though, including all ECDSA and Ed25519
operations, should be fine even in pure Perl.

Note that this distribution’s test suite is also pretty slow without an
XS backend.

# TODO

There are TODO items listed in the submodules; the following are general
to the entire distribution.

- Document the exception system so that applications can use it.
- Add more tests, e.g., against [CryptX](https://metacpan.org/pod/CryptX).
- Some formal security audit would be nice.
- Make it faster :)

# ACKNOWLEDGEMENTS

Much of the logic here comes from Kenji Urushima’s [jsrsasign](https://github.com/kjur/jsrsasign).

Most of the tests depend on the near-ubiquitous [OpenSSL](http://openssl.org),
without which the Internet would be a very, very different reality from
what we know!

The Ed25519 logic is ported from [forge.js](https://github.com/digitalbazaar/forge/blob/master/lib/ed25519.js).

Deterministic ECDSA logic derived in part from
[python-ecdsa](https://github.com/ecdsa/python-ecdsa).

Other parts are ported from [LibTomCrypt](http://www.libtom.net).

Special thanks to Antonio de la Piedra for having submitted
multiple high-quality, in-depth bug reports.

# LICENSE

This library is licensed under the same license as Perl.

# AUTHOR

Felipe Gasper (FELIPE)
