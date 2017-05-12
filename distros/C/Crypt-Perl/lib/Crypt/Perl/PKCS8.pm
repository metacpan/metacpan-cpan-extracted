package Crypt::Perl::PKCS8;

#TODO: Rename this, and split up the public/private as appropriate.

use strict;
use warnings;

use constant ASN1 => <<END;
    -- FG: simplified from RFC for Convert::ASN1
    Version ::= INTEGER

    -- cf. RFC 3280 4.1.1.2
    AlgorithmIdentifier  ::=  SEQUENCE  {
        algorithm   OBJECT IDENTIFIER,
        parameters  ANY DEFINED BY algorithm OPTIONAL
    }

    -- cf. RFC 5208 appendix A
    PrivateKeyInfo ::= SEQUENCE {
        version             Version,
        privateKeyAlgorithm AlgorithmIdentifier,
        privateKey          PrivateKey
    }

    PrivateKey ::= OCTET STRING

    -- cf. RFC 3280 4.1
    SubjectPublicKeyInfo  ::=  SEQUENCE  {
        algorithm            AlgorithmIdentifier,
        subjectPublicKey     BIT STRING
    }
END

1;
