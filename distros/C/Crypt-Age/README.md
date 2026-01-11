# Crypt::Age

Perl implementation of the [age encryption format](https://age-encryption.org).

## Synopsis

```perl
use Crypt::Age;

# Generate a keypair
my ($public_key, $secret_key) = Crypt::Age->generate_keypair();
# $public_key = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
# $secret_key = "AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ3290DG"

# Encrypt data
my $encrypted = Crypt::Age->encrypt(
    plaintext  => "Hello, World!",
    recipients => [$public_key],
);

# Decrypt data
my $decrypted = Crypt::Age->decrypt(
    ciphertext => $encrypted,
    identities => [$secret_key],
);

# Encrypt a file
Crypt::Age->encrypt_file(
    input      => 'secret.txt',
    output     => 'secret.txt.age',
    recipients => [$public_key],
);

# Decrypt a file
Crypt::Age->decrypt_file(
    input      => 'secret.txt.age',
    output     => 'secret.txt',
    identities => [$secret_key],
);
```

## Description

age is a simple, modern and secure file encryption tool with small explicit keys, no config options, and UNIX-style composability.

This module provides a pure Perl implementation of the age encryption format, fully compatible with:

- [age](https://github.com/FiloSottile/age) - The reference Go implementation
- [rage](https://github.com/str4d/rage) - A Rust implementation

Files encrypted with Crypt::Age can be decrypted with these tools and vice versa.

## Features

- X25519 key exchange for secure key agreement
- ChaCha20-Poly1305 AEAD for authenticated encryption
- HKDF-SHA256 for key derivation
- Bech32 key encoding (age1.../AGE-SECRET-KEY-1...)
- Multiple recipients support
- Binary-safe encryption
- Streaming encryption for large files (64KB chunks)

## Key Format

### Public Keys

Public keys are Bech32-encoded with the human-readable part `age`:

```
age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

### Secret Keys

Secret keys are uppercase Bech32-encoded with the human-readable part `AGE-SECRET-KEY-`:

```
AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ3290DG
```

## Installation

```bash
cpanm Crypt::Age
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

## Dependencies

- [CryptX](https://metacpan.org/pod/CryptX) - Provides X25519, ChaCha20-Poly1305, HKDF, and HMAC
- [Moo](https://metacpan.org/pod/Moo) - Object system

## Testing

```bash
# Run all tests
prove -l t/

# Verbose output
prove -lv t/

# Run specific test
prove -lv t/02-encrypt-decrypt.t
```

If you have `age` or `rage` installed, interoperability tests will also run:

```bash
# Install age (on macOS)
brew install age

# Install rage (via cargo)
cargo install rage
```

## Specification

This implementation follows the [age specification](https://github.com/C2SP/C2SP/blob/main/age.md).

### File Format

An age-encrypted file consists of:

1. **Header** (text) - Version, recipient stanzas, and MAC
2. **Payload** (binary) - ChaCha20-Poly1305 encrypted content in 64KB chunks

```
age-encryption.org/v1
-> X25519 <ephemeral-public-key-base64>
<wrapped-file-key-base64>
--- <header-mac-base64>
<binary encrypted payload>
```

## Cryptographic Primitives

| Primitive | Purpose |
|-----------|---------|
| X25519 | Key exchange between sender and recipient |
| ChaCha20-Poly1305 | Authenticated encryption of file key and payload |
| HKDF-SHA256 | Key derivation for wrap key, payload key, and MAC key |
| HMAC-SHA256 | Header authentication |

## Current Limitations

- Only X25519 recipients are supported (no passphrase or SSH keys yet)
- No armored (PEM-like) output format
- No plugin support

## See Also

- [age-encryption.org](https://age-encryption.org) - Official age homepage
- [age specification](https://github.com/C2SP/C2SP/blob/main/age.md) - Format specification
- [filippo.io/age](https://pkg.go.dev/filippo.io/age) - Go implementation docs

## Author

Torsten Raudssus <torsten@raudssus.de>

## License

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
