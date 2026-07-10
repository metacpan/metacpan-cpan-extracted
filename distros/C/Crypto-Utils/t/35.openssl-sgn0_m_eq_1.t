use strict;
use warnings;

use Test::More;
use Crypto::Utils::OpenSSL;

my $z = BN_new();
BN_dec2bn( $z, '99' );
my $z_hex = BN_bn2hex($z);
my $ret   = sgn0_m_eq_1($z);
is( $ret, 1, "0x$z_hex sgn0 : $ret" );

$z = BN_new();
BN_dec2bn( $z, '200' );
$z_hex = BN_bn2hex($z);
$ret   = sgn0_m_eq_1($z);
is( $ret, 0, "0x$z_hex sgn0 : $ret" );

done_testing;
