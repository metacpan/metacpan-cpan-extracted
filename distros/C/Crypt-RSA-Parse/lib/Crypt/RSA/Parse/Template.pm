package Crypt::RSA::Parse::Template;

#cf. RFC 3447 appendix A.1.1
#
#replacing INTEGER with FG_FAUX_INTEGER to facilitate “lite” mode
#which doesn’t bring in Math::BigInt.
my $ASN1_TEMPLATE = q<

    FG_FAUX_INTEGER ::= <WHAT_IS_FG_FAUX_INTEGER>

    RSAPublicKey ::= SEQUENCE {
        modulus           FG_FAUX_INTEGER,  -- n
        publicExponent    FG_FAUX_INTEGER   -- e
    }

    -- FG: simplified from RFC for Convert::ASN1
    Version ::= INTEGER

    OtherPrimeInfo ::= SEQUENCE {
        prime             FG_FAUX_INTEGER,  -- ri
        exponent          FG_FAUX_INTEGER,  -- di
        coefficient       FG_FAUX_INTEGER   -- ti
    }

    -- FG: simplified from RFC for Convert::ASN1
    OtherPrimeInfos ::= SEQUENCE OF OtherPrimeInfo

    RSAPrivateKey ::= SEQUENCE {
        version           Version,
        modulus           FG_FAUX_INTEGER,  -- n
        publicExponent    INTEGER,  -- e
        privateExponent   FG_FAUX_INTEGER,  -- d
        prime1            FG_FAUX_INTEGER,  -- p
        prime2            FG_FAUX_INTEGER,  -- q
        exponent1         FG_FAUX_INTEGER,  -- d mod (p-1)
        exponent2         FG_FAUX_INTEGER,  -- d mod (q-1)
        coefficient       FG_FAUX_INTEGER,  -- (inverse of q) mod p
        otherPrimeInfos   OtherPrimeInfos OPTIONAL
    }

    -- cf. RFC 3280 4.1.1.2
    AlgorithmIdentifier  ::=  SEQUENCE  {
        algorithm               OBJECT IDENTIFIER,
        parameters              ANY DEFINED BY algorithm OPTIONAL
    }

    -- cf. RFC 5208 appendix A
    PrivateKeyInfo ::= SEQUENCE {
        version Version,
        privateKeyAlgorithm AlgorithmIdentifier,
        privateKey PrivateKey
    }

    PrivateKey ::= OCTET STRING

    -- cf. RFC 3280 4.1
    SubjectPublicKeyInfo  ::=  SEQUENCE  {
        algorithm            AlgorithmIdentifier,
        subjectPublicKey     BIT STRING
    }
>;

sub get_template {
    my ($what_is_big_fat_int) = @_;

    my $template = $ASN1_TEMPLATE;
    $template =~ s/<WHAT_IS_FG_FAUX_INTEGER>/$what_is_big_fat_int/;

    return $template;
}

1;
