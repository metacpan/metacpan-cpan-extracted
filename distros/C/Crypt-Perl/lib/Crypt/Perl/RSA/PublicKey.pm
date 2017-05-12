package Crypt::Perl::RSA::PublicKey;

=encoding utf-8

=head1 NAME

Crypt::Perl::RSA::PublicKey - object representation of an RSA public key

=head1 SYNOPSIS

    #You’ll probably instantiate this class using Parser.pm
    #or PrivateKey’s get_public_key() method.

    #cf. JSON Web Algorithms (RFC 7518, page 5)
    #These return 1 or 0 to indicate verification or non-verification.
    $pbkey->verify_RS256($message, $sig);
    $pbkey->verify_RS384($message, $sig);
    $pbkey->verify_RS512($message, $sig);

    #----------------------------------------------------------------------

    my $enc = $pbkey->encrypt_raw($payload);

    #----------------------------------------------------------------------

    my $der = $pbkey->to_der();
    my $pem = $pbkey->to_pem();

    #For use in creating PKCS #10 CSRs and X.509 certificates
    my $pub_der = $pbkey->to_subject_der();

    #----------------------------------------------------------------------

    $pbkey->size();                 #modulus length, in bits
    $pbkey->modulus_byte_length();

    #----------------------------------------------------------------------
    # The following all return instances of Crypt::Perl::BigInt,
    # a subclass of Math::BigInt.
    # The pairs (e.g., modulus() and N()) are aliases.
    #----------------------------------------------------------------------

    $pbkey->modulus();
    $pbkey->N();

    $pbkey->publicExponent();
    $pbkey->E();
    $pbkey->exponent();         #another alias of publicExponent()

=cut

use strict;
use warnings;

use parent qw(
    Crypt::Perl::RSA::KeyBase
);

use constant _PEM_HEADER => 'RSA PUBLIC KEY';
use constant _ASN1_MACRO => 'RSAPublicKey';

BEGIN {
    *exponent = __PACKAGE__->can('publicExponent');
    *to_subject_der = __PACKAGE__->can('_to_subject_public_der');
}

1;
