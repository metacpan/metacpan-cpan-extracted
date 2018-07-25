package Crypt::Perl::PKCS8;

#TODO: Rename this, and split up the public/private as appropriate.

use strict;
use warnings;

use Crypt::Perl::ASN1 ();

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

sub parse_private {
    my ($pem_or_der) = @_;

    return _asn1()->find('PrivateKeyInfo')->decode($pem_or_der);
}

sub parse_public {
    my ($pem_or_der) = @_;

    return _asn1()->find('SubjectPublicKeyInfo')->decode($pem_or_der);
}

sub _asn1 {
    return Crypt::Perl::ASN1->new()->prepare( Crypt::Perl::PKCS8::ASN1() );
}

1;
