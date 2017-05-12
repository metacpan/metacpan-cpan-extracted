use strict;
use warnings;

use Crypt::SRP;
use Test::More tests => 1;

my $Hex = 'beb25379d1a8581eb5a727673a2441ee';
my $Bytes1 = pack('H*', $Hex);
my $Num = Crypt::SRP::_bytes2bignum($Bytes1);
my $Bytes2 = Crypt::SRP::_bignum2bytes($Num);
is(lc(unpack("H*", $Bytes2)), lc($Hex), 'bignum test');
