package Crypt::Perl::PKCS10::ASN1;

use strict;
use warnings;

our %OID = (
    extensionRequest => '1.2.840.113549.1.9.14',
    subjectAltName => '2.5.29.17',

    sha256WithRSAEncryption => '1.2.840.113549.1.1.11',
    sha384WithRSAEncryption => '1.2.840.113549.1.1.12',
    sha512WithRSAEncryption => '1.2.840.113549.1.1.13',

    ecPublicKey => '1.2.840.10045.2.1',
    rsaEncryption => '1.2.840.113549.1.1.1',

    'ecdsa-with-SHA224' => '1.2.840.10045.4.3.1',
    'ecdsa-with-SHA256' => '1.2.840.10045.4.3.2',
    'ecdsa-with-SHA384' => '1.2.840.10045.4.3.3',
    'ecdsa-with-SHA512' => '1.2.840.10045.4.3.4',
);

1;
