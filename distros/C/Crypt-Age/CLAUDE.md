# Crypt::Age

Perl implementation of the age encryption format (age-encryption.org/v1).

## Project Goal

Pure Perl implementation of the age file encryption format, compatible with the reference Go implementation (filippo.io/age) and Rust implementation (rage).

## Specification

- Format spec: https://github.com/C2SP/C2SP/blob/main/age.md
- Reference: https://age-encryption.org

## File Format Overview

An age file has two parts:
1. **Header** (text) - Contains encrypted file key and MAC
2. **Payload** (binary) - File content encrypted with ChaCha20-Poly1305

### Header Structure
```
age-encryption.org/v1
-> X25519 <ephemeral-public-key>
<encrypted-file-key>
--- <base64-MAC>
<binary payload>
```

## Cryptographic Primitives Needed

All available in CryptX on CPAN:

| Primitive | Use | CPAN Module |
|-----------|-----|-------------|
| X25519 | Key exchange | `Crypt::PK::X25519` (CryptX) |
| ChaCha20-Poly1305 | AEAD encryption | `Crypt::AuthEnc::ChaCha20Poly1305` (CryptX) |
| HKDF-SHA256 | Key derivation | `Crypt::KeyDerivation` (CryptX) |
| HMAC-SHA256 | Header MAC | `Crypt::Mac::HMAC` (CryptX) |

## Recipient Types (Phase 1)

Start with X25519 recipients only:
- `age1...` public keys (Bech32 encoded)
- `-r` recipient flag compatible

Later phases:
- Passphrase recipients (scrypt)
- SSH key recipients (ssh-ed25519, ssh-rsa)

## API Design

```perl
use Crypt::Age;

# Generate keypair
my ($public, $private) = Crypt::Age->generate_keypair();
# $public  = "age1..."
# $private = "AGE-SECRET-KEY-1..."

# Encrypt
my $encrypted = Crypt::Age->encrypt(
    plaintext  => $data,
    recipients => ['age1abc...', 'age1def...'],
);

# Decrypt
my $decrypted = Crypt::Age->decrypt(
    ciphertext => $encrypted,
    identities => ['AGE-SECRET-KEY-1...'],
);

# File-based
Crypt::Age->encrypt_file(
    input      => 'secret.txt',
    output     => 'secret.txt.age',
    recipients => \@recipients,
);

Crypt::Age->decrypt_file(
    input      => 'secret.txt.age',
    output     => 'secret.txt',
    identities => \@identities,
);
```

## Key Format

### Public Key (Bech32)
- HRP: `age`
- 32 bytes X25519 public key
- Example: `age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p`

### Secret Key (Bech32)
- HRP: `AGE-SECRET-KEY-`
- 32 bytes X25519 secret key
- Example: `AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ3290DG`

## Dependencies

```perl
# cpanfile
requires 'CryptX';           # All crypto primitives
requires 'Crypt::Misc';      # Base64, Bech32 helpers
```

## Testing

- Test vectors from age specification
- Interoperability tests with `age` CLI
- Round-trip tests (encrypt/decrypt)

## Files to Create

```
lib/
├── Crypt/
│   ├── Age.pm                 # Main interface
│   └── Age/
│       ├── Header.pm          # Header parsing/generation
│       ├── Recipient.pm       # Recipient handling
│       ├── Recipient/
│       │   └── X25519.pm      # X25519 recipient type
│       ├── Identity.pm        # Identity (private key) handling
│       ├── Keys.pm            # Key generation, Bech32 encoding
│       └── Primitives.pm      # Low-level crypto operations
t/
├── 00-load.t
├── 01-keys.t
├── 02-encrypt-decrypt.t
├── 03-header.t
└── 04-interop.t              # Test with age CLI
```

## References

- https://github.com/FiloSottile/age
- https://github.com/C2SP/C2SP/blob/main/age.md
- https://pkg.go.dev/filippo.io/age
- https://docs.rs/age/latest/age/
