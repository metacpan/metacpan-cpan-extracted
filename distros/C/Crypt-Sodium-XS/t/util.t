use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Util ":all";

my $nonce = scalar("\xff" x 6) . scalar("\xfe" x (24 - 6));
$nonce = sodium_increment($nonce);
is(unpack("H*", $nonce), "000000000000fffefefefefefefefefefefefefefefefefe",
   "sodium_increment() (xFF x 6)");

$nonce = scalar("\xff" x 10) . scalar("\xfe" x (24 - 10));
$nonce = sodium_increment($nonce);
is(unpack("H*", $nonce), "00000000000000000000fffefefefefefefefefefefefefe",
   "sodium_increment() (xFF x 10)");


$nonce = scalar("\xff" x 22) . scalar("\xfe" x (24 - 22));
$nonce = sodium_increment($nonce);
is(unpack("H*", $nonce), "00000000000000000000000000000000000000000000fffe",
   "sodium_increment() (xFF x 22)");

my $str = "foobarbaz";
my $str2 = "more";
sodium_memzero($str);
is($str, scalar("\0" x 9), "sodium_memzero nulls string");
$str = "foobarbaz";
sodium_memzero($str, $str2);
is($str . $str2, scalar("\0" x 13), "sodium_memzero multiple args");

my $x = "\x01";
$x = sodium_add($x, "\x01");
is(unpack("H*", $x), "02", "sodium_add right answer");
$x = sodium_sub($x, "\x01");
is(unpack("H*", $x), "01", "sodium_sub right answer");
$x = "\xbd\xbd\xbd\xbd";
$x = sodium_add($x, "\x01\x02");
is(unpack("H*", $x), "bebfbdbd", "sodium_add with rhs shorter");
$x = sodium_sub($x, "\x01\x02");
is(unpack("H*", $x), "bdbdbdbd", "sodium_sub with rhs shorter");
$x = sodium_add("\x01\x02", $x);
is(unpack("H*", $x), "bebfbdbd", "sodium_add with lhs shorter, lhs constant");
$x = "\xff\xff";
$x = sodium_add($x, "\x01\x02");
is(unpack("H*", $x), "0002", "sodium_add with overflow");
$x = sodium_sub($x, "\x01\x02");
is(unpack("H*", $x), "ffff", "sodium_sub with overflow");
$x = "\xff\xff\xff";
$x = sodium_add($x, "\x01");
is(unpack("H*", $x), "000000", "sodium_add with overflow, lhs shorter");
$x = sodium_sub($x, "\x01");
is(unpack("H*", $x), "ffffff", "sodium_sub with overflow, lhs shorter");
$x = sodium_add("\x03", $x);
is(unpack("H*", $x), "020000", "sodium_add with overflow, lhs shorter, lhs constant");
$x = sodium_sub("\x01", $x);
is(unpack("H*", $x), "ffffff", "sodium_sub with overflow, lhs shorter, lhs constant");

$x = "\xbd\xbd\xbd\xbd";
my $y = "\xbd\xbd\xbd\xbd";
ok(sodium_memcmp($x, $y), "memcmp: equivalent arguments returns true");
ok(!sodium_compare($x, $y), "compare: equivalent arguments returns false");
$y = "\xbd\xbd\xbd\xff";
ok(!sodium_memcmp($x, $y), "memcmp: different arguments returns true");
ok(sodium_compare($x, $y) == -1, "compare: less than returns -1");
$y = "\xbd\xbd\xbd\x11";
ok(sodium_compare($x, $y) == 1, "compare: greater than returns 1");
ok(sodium_memcmp($x, $y, 2), "memcmp: equivalent arguments (length) returns true");
ok(!sodium_compare($x, $y, 2), "compare: equivalent arguments (length) returns false");
eval { sodium_memcmp($x, "\1\2") };
like($@, qr/Length of operands must be equal/, "memcmp: invalid lengths");
eval { sodium_compare($x, "\1\2") };
like($@, qr/Length of operands must be equal/, "compare: invalid lengths");

ok(sodium_is_zero("\0\0\0\0\0"), "sodium_is_zero detects zero");
ok(!sodium_is_zero("\0\0\0\0\0\1\0"), "sodium_is_zero detects not zero");

is(sodium_bin2hex("foobar"), "666f6f626172", "sodium_hex2bin correct");
is(sodium_hex2bin("666f6f626172"), "foobar", "sodium_bin2hex correct");
is(sodium_hex2bin("666f6f626172:6666"), "foobar", "sodium_bin2hex stops parsing at invalid hex");
is(sodium_hex2bin("666f6f6261726"), "", "sodium_bin2hex returns empty when unparsable");

done_testing();
