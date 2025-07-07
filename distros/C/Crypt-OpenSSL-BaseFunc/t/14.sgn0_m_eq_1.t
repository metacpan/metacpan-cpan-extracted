use strict;
use warnings;

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;

my $z = Crypt::OpenSSL::Bignum->new_from_decimal('99');
my $z_hex = $z->to_hex();
my $ret = sgn0_m_eq_1($z);
is($ret, 1, "0x$z_hex sgn0 : $ret");

$z = Crypt::OpenSSL::Bignum->new_from_decimal('200');
$z_hex = $z->to_hex();
$ret = sgn0_m_eq_1($z);
is($ret, 0, "0x$z_hex sgn0 : $ret");


done_testing;
