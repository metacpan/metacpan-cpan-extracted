# NAME

Crypto::ECC - Perl Elliptic Curve DSA and DH

# DESCRIPTION

For more information on Elliptic Curve Cryptography please read http://matejdanter.com/2010/12/elliptic-curve-php-oop-dsa-and-diffie-hellman/

Requires GMP or bcmath extension, GMP preferred for better performance.

# USAGE

    use Crypto::ECC;

and then the short version of the class names will be imported

    $CurveFp   --> 'Crypto::ECC::CurveFp';
    $Point     --> 'Crypto::ECC::Point';
    $PublicKey --> 'Crypto::ECC::PublicKey';
    $Signature --> 'Crypto::ECC::Signature';

You don't have to use these classname aliases. It is just for my convenience.

# CREDIT

Direct Translation from PHP to Perl - https://github.com/phpecc/phpecc/tree/366c0d1d00cdf95b0511d34797c116d9be48410e

# NOTE

These classes are not fully copied from the PHP version. Only copied enough to support DigiByte::DigiID

Please email me if you wish to extends functions or become a contributor.

# MIT Licence

Licensed under the MIT License.
