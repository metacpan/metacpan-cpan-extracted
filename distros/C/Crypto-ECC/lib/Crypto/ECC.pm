package Crypto::ECC;
$Crypto::ECC::VERSION = '0.004';
use Crypto::ECC::CurveFp;
use Crypto::ECC::Point;
use Crypto::ECC::PublicKey;
use Crypto::ECC::Signature;

use base 'Exporter';

our @EXPORT = qw(
  $Point
  $CurveFp
  $PublicKey
  $Signature
);

our $CurveFp   = 'Crypto::ECC::CurveFp';
our $Point     = 'Crypto::ECC::Point';
our $PublicKey = 'Crypto::ECC::PublicKey';
our $Signature = 'Crypto::ECC::Signature';

1;

=head1 NAME

Crypto::ECC - Perl Elliptic Curve DSA and DH

=head1 DESCRIPTION

For more information on Elliptic Curve Cryptography please read http://matejdanter.com/2010/12/elliptic-curve-php-oop-dsa-and-diffie-hellman/

Requires GMP or bcmath extension, GMP preferred for better performance.

=head1 USAGE

 use Crypto::ECC;

and then the short version of the class names will be imported

 $CurveFp   --> 'Crypto::ECC::CurveFp';
 $Point     --> 'Crypto::ECC::Point';
 $PublicKey --> 'Crypto::ECC::PublicKey';
 $Signature --> 'Crypto::ECC::Signature';

You don't have to use these classname aliases. It is just for my convenience.

=head1 CREDIT

Direct Translation from PHP to Perl - https://github.com/phpecc/phpecc/tree/366c0d1d00cdf95b0511d34797c116d9be48410e

=head1 NOTE

These classes are not fully copied from the PHP version. Only copied enough to support DigiByte::DigiID

Please email me if you wish to extends functions or become a contributor.

=head1 MIT Licence

Licensed under the MIT License.

=cut
