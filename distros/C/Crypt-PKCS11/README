# Crypt::PKCS11 - Full-fledged PKCS #11 v2.30 interface

## SYNPOSIS

```
use Crypt::PKCS11;

# Create the main PKCS #11 object, load a PKCS #11 provider .so library and initialize the module
my $pkcs11 = Crypt::PKCS11->new;
$pkcs11->load(...);
$pkcs11->Initialize;

# Create a new session and log in
my $session = $pkcs11->OpenSession(...);
$session->Login(...);

# Create the public key template
my $publicKeyTemplate = Crypt::PKCS11::Attributes->new->push(
    Crypt::PKCS11::Attribute::Encrypt->new->set(1),
    Crypt::PKCS11::Attribute::Verify->new->set(1),
    Crypt::PKCS11::Attribute::Wrap->new->set(1),
    Crypt::PKCS11::Attribute::PublicExponent->new->set(0x01, 0x00, 0x01),
    Crypt::PKCS11::Attribute::Token->new->set(1),
    Crypt::PKCS11::Attribute::ModulusBits->new->set(768)
);

# Create the private key template
my $privateKeyTemplate = Crypt::PKCS11::Attributes->new->push(
    Crypt::PKCS11::Attribute::Private->new->set(1),
    Crypt::PKCS11::Attribute::Id->new->set(123),
    Crypt::PKCS11::Attribute::Sensitive->new->set(1),
    Crypt::PKCS11::Attribute::Decrypt->new->set(1),
    Crypt::PKCS11::Attribute::Sign->new->set(1),
    Crypt::PKCS11::Attribute::Unwrap->new->set(1),
    Crypt::PKCS11::Attribute::Token->new->set(1)
);

# Create a public and private key pair
my ($publicKey, $privateKey) = $session->GenerateKeyPair(
    Crypt::PKCS11::CK_MECHANISM->new->set_mechanism(...),
    $publicKeyTemplate,
    $privateKeyTemplate);

# Encrypt data
my $data = ...;
$session->EncryptInit(
    Crypt::PKCS11::CK_MECHANISM->new->set_mechanism(...),
    $privateKey);
my $encryptedData = $session->Encrypt($data);
$encryptedData .= $session->EncryptFinal;

# Decrypt data
$session->DecryptInit(
    Crypt::PKCS11::CK_MECHANISM->new->set_mechanism(...),
    $privateKey);
$data = $session->Decrypt($encryptedData);
$data .= $session->DecryptFinal;

# Finalize the PKCS #11 module and unload the provider .so library
$pkcs11->Finalize;
$pkcs11->unload;
```

## DESCRIPTION

Crypt::PKCS11 provides a full-fledged PKCS #11 v2.30 interface for Perl and
together with a PKCS #11 provider .so library you can use all the functionality
a Hardware Security Module (HSM) has to offer from within Perl.

Other modules/pod sections included are:

### Crypt::PKCS11::XS

XS layer containing wrappers for all PKCS #11 functions that converts Perl data
structures to/from PKCS #11 specific data structures.

### Crypt::PKCS11::Session

A module handling everything related to a PKCS #11 session.

### Crypt::PKCS11::Object

A module that represent a PKCS #11 object which for example can be a public or
private key.

### Crypt::PKCS11::Attribute

A module that represent a PKCS #11 attribute that are used in templates when for
example creating keys. This is only a base class, see
`Crypt::PKCS11::Attributes` for a list of all available attributes.

### Crypt::PKCS11::Attributes

A module to handle a set of Crypt::PKCS11::Attribute objects and also lists all
available PKCS #11 attributes.

### Crypt::PKCS11::constant

List of all PKCS #11 constants.

### Crypt::PKCS11::Attribute::AttributeArray

A base module that handles nested PKCS #11 attributes.

### Crypt::PKCS11::Attribute::ByteArray

A base module that handles byte array attributes.

### Crypt::PKCS11::Attribute::CK_BBOOL

A base module that handles boolean attributes.

### Crypt::PKCS11::Attribute::CK_BYTE

A base module that handles one byte attributes.

### Crypt::PKCS11::Attribute::CK_DATE

A base module that handles date attributes.

### Crypt::PKCS11::Attribute::CK_ULONG

A base module that handles an unsigned long attributes.

### Crypt::PKCS11::Attribute::RFC2279string

A base module that handles RFC 2279 string attributes.

### Crypt::PKCS11::Attribute::UlongArray

A base module that handles unsigned long array attributes.

### Crypt::PKCS11::Attribute::Value

A base module that handles attributes containing either a byte array or a binary
string.

## QUALITY ASSURANCE AND TESTING

This module is currently tested on Ubuntu 12.04 and with SoftHSM version 1.3.7
and 2.0.0b2 as PKCS #11 providers / HSM backends. It uses Test::LeakTrace to
detect leaks and Devel::Cover to provide coverage reports. The goal is to always
be non-leaking and to have 100% coverage. See README.testing.md for more
information how to test.

```
---------------------------- ------ ------ ------ ------ ------ ------ ------
File                           stmt   bran   cond    sub    pod   time  total
---------------------------- ------ ------ ------ ------ ------ ------ ------
blib/lib/Crypt/PKCS11.pm      100.0  100.0  100.0  100.0  100.0   92.6  100.0
...Crypt/PKCS11/Attribute.pm  100.0  100.0  100.0  100.0  100.0    0.1  100.0
...tribute/AttributeArray.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
...11/Attribute/ByteArray.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
...S11/Attribute/CK_BBOOL.pm  100.0  100.0    n/a  100.0  100.0    0.0  100.0
...CS11/Attribute/CK_BYTE.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
...CS11/Attribute/CK_DATE.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
...S11/Attribute/CK_ULONG.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
...ttribute/RFC2279string.pm  100.0  100.0    n/a  100.0  100.0    0.0  100.0
...1/Attribute/UlongArray.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
...PKCS11/Attribute/Value.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
...rypt/PKCS11/Attributes.pm  100.0  100.0  100.0  100.0  100.0    4.8  100.0
...ib/Crypt/PKCS11/Object.pm  100.0  100.0  100.0  100.0  100.0    1.9  100.0
...b/Crypt/PKCS11/Session.pm  100.0  100.0  100.0  100.0  100.0    0.5  100.0
crypt_pkcs11.c                100.0  100.0    n/a    n/a    n/a    n/a  100.0
crypt_pkcs11_struct.c         100.0  100.0    n/a    n/a    n/a    n/a  100.0
pkcs11.xs                     100.0    n/a    n/a    n/a    n/a    n/a  100.0
pkcs11_struct.xs              100.0    n/a    n/a    n/a    n/a    n/a  100.0
Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
---------------------------- ------ ------ ------ ------ ------ ------ ------
```

This module has been tested with the following PKCS #11 providers and operating
systems:

* Ubuntu Server 12.04 using SoftHSM version 1.3.7 and 2.0.0b2

More platforms and PKCS #11 providers will be added in the future.

## NOTE

Derived from the RSA Security Inc. PKCS #11 Cryptographic Token Interface (Cryptoki)

## AUTHOR

Jerry Lundström <lundstrom.jerry@gmail.com>

## REPORTING BUGS

Report bugs at https://github.com/dotse/p5-Crypt-PKCS11/issues .

## LICENSE

```
Copyright (c) 2015 Jerry Lundström <lundstrom.jerry@gmail.com>
Copyright (c) 2015 .SE (The Internet Infrastructure Foundation)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
