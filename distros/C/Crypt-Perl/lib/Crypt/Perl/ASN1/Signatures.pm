package Crypt::Perl::ASN1::Signatures;

use strict;
use warnings;

our %OID = (
    sha224WithRSAEncryption => '1.2.840.113549.1.1.14',
    sha256WithRSAEncryption => '1.2.840.113549.1.1.11',
    sha384WithRSAEncryption => '1.2.840.113549.1.1.12',
    sha512WithRSAEncryption => '1.2.840.113549.1.1.13',

    'ecdsa-with-SHA224' => '1.2.840.10045.4.3.1',
    'ecdsa-with-SHA256' => '1.2.840.10045.4.3.2',
    'ecdsa-with-SHA384' => '1.2.840.10045.4.3.3',
    'ecdsa-with-SHA512' => '1.2.840.10045.4.3.4',

    'ed25519' => '1.3.101.112',
);

1;
