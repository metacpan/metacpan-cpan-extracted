[![Build Status](https://travis-ci.org/sophos/Crypt-PKCS11-Easy.svg?branch=master)](https://travis-ci.org/sophos/Crypt-PKCS11-Easy)
[![Coverage Status](https://coveralls.io/repos/github/sophos/Crypt-PKCS11-Easy/badge.svg?branch=master)](https://coveralls.io/github/sophos/Crypt-PKCS11-Easy?branch=master)
[![Kwalitee status](http://cpants.cpanauthors.org/dist/Crypt-PKCS11-Easy.png)](http://cpants.charsbar.org/dist/overview/Crypt-PKCS11-Easy)
[![GitHub issues](https://img.shields.io/github/issues/sophos/Crypt-PKCS11-Easy.svg)](https://github.com/sophos/Crypt-PKCS11-Easy/issues)
[![GitHub tag](https://img.shields.io/github/tag/sophos/Crypt-PKCS11-Easy.svg)]()
[![Cpan license](https://img.shields.io/cpan/l/Crypt-PKCS11-Easy.svg)](https://metacpan.org/release/Crypt-PKCS11-Easy)
[![Cpan version](https://img.shields.io/cpan/v/Crypt-PKCS11-Easy.svg)](https://metacpan.org/release/Crypt-PKCS11-Easy)

# SYNOPSIS
```perl

use Crypt::PKCS11::Easy;
use IO::Prompter;

my $file = '/file/to/sign';

my $hsm = Crypt::PKCS11::Easy->new(
    module => 'libCryptoki2_64',
    key    => 'MySigningKey',
    slot   => '0',
    pin    => sub { prompt 'Enter PIN: ', -echo=>'*' },
);

my $base64_signature = $hsm->sign_and_encode(file => $file);
my $binary_signature = $hsm->decode_signature(data => $base64_signature);

$hsm->verify(file => $data_file, sig => $binary_signature)
  or die "VERIFICATION FAILED\n";
```

# DESCRIPTION

This module is an OO wrapper around [Crypt::PKCS11](https://metacpan.org/pod/Crypt::PKCS11), designed primarily to make
using a HSM as simple as possible.

## Signing a file with `Crypt::PKCS11`
```perl
use IO::Prompter;
use Crypt::PKCS11;
use Crypt::PKCS11::Attributes;

my $pkcs11 = Crypt::PKCS11->new;
$pkcs11->load('/usr/safenet/lunaclient/lib/libCryptoki2_64.so');
$pkcs11->Initialize;
# assuming there is only one slot
my @slot_ids = $pkcs11->GetSlotList(1);
my $slot_id = shift @slot_ids;

my $session = $pkcs11->OpenSession($slot_id, CKF_SERIAL_SESSION)
    or die "Error" . $pkcs11->errstr;

$session->Login(CKU_USER, sub { prompt 'Enter PIN: ', -echo=>'*' } )
    or die "Failed to login: " . $session->errstr;

my $object_template = Crypt::PKCS11::Attributes->new->push(
    Crypt::PKCS11::Attribute::Label->new->set('MySigningKey'),
    Crypt::PKCS11::Attribute::Sign->new->set(1),
);
$session->FindObjectsInit($object_template);
my $objects = $session->FindObjects(1);
my $key = shift @$objects;

my $sign_mech = Crypt::PKCS11::CK_MECHANISM->new;
$sign_mech->set_mechanism(CKM_SHA1_RSA_PKCS);

$session->SignInit($sign_mech, $key)
    or die "Failed to set init signing: " . $session->errstr;

my $sig = $session->Sign('SIGN ME')
    or die "Failed to sign: " . $session->errstr;
```

## Signing a file with `Crypt::PKCS11::Easy`
```perl
use Crypt::PKCS11::Easy;
use IO::Prompter;

my $hsm = Crypt::PKCS11::Easy->new(
    module => 'libCryptoki2_64',
    key    => 'MySigningKey',
    slot   => '0',
    pin    => sub { prompt 'Enter PIN: ', -echo=>'*' },
);

my $sig = $hsm->sign(data => 'SIGN ME');
```

To make that conciseness possible a `Crypt::PKCS11::Object` can only be used
for one function, e.g. signing OR verifying, and cannot be set to use a
different key or a different token after instantiation. A new object should be
created for each function.

# SEE ALSO

* [PKCS#11 v2.40 Mechanisms](http://docs.oasis-open.org/pkcs11/pkcs11-curr/v2.40/os/pkcs11-curr-v2.40-os.html)
* [Crypt::PKCS11](https://metacpan.org/pod/Crypt::PKCS11)
* [SoftHSM2](https://www.opendnssec.org/softhsm/)
