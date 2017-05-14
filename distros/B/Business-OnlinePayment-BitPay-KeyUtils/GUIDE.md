# Using the BitPay Key Utilities Library

This library provides utilities for use with the BitPay API. It enables creating keys, retrieving public keys, creating the SIN that is used in retrieving tokens from BitPay, and signing payloads for the `X-Signature` header in a BitPay API request.

# Prerequisites
 * libssl-dev (OpenSSL 0.9.8+)
 * SWIG (3.0.5+)
 * Perl (5.18+)
 * Make

## Quick Start
### Installation

Install from cpan by typing the following:

```bash
sudo cpanm BitPay::KeyUtils
```

or

Clone the github repository and type the following:

```bash
perl Makefile.PL
make
make test
sudo make install
```

### Usage
Use the key utils by including `use BitPay::key_utils` in your project. This should give you access to the functions:

```perl
my $pem = BitPay::KeyUtils::bpGeneratePem(); #creates ECDSA Keys and sets the value of pem to the PEM encoding of the key
my $pub = BitPay::KeyUtils::bpGetPublicKeyFromPem($pem); #takes a pem string and sets the value of pubkey to the compressed public key extracted from the pem
my $sin = BitPay::KeyUtils::bpGenerateSinFromPem($pem); #gets the base58 unique identifier associated with the pem
my $signature = BitPay::KeyUtils::bpSignMessageWithPem($pem, "He's dead, Jim."); #sets signature to the signature of the sha256 of the message
```

## Dev Environment

Clone the github repository.

```bash
./clean
./build
```

## API Documentation

API Documentation is available on the [BitPay site](https://bitpay.com/api).

## Running the Tests

```bash
$ perl test.pl
```
