use strict;
use warnings;
use Archive::Rgssad::Keygen 'keygen';
use Test::More tests => 10;

sub test {
  my ($got, $exptected, $test_name) = @_;
  is(pack('V', $got), pack('V', $exptected), $test_name);
}

my @keys = (0xdeadcafe, 0x16c08cf5, 0x9f43dab6, 0x5adafafd, 0x7bfcdcee, 0x63ea0a85);
my ($key, $ret, @ret);

$key = $keys[0];
$ret = keygen($key);
test($ret, $keys[0], 'return old key');
test($key, $keys[1], 'update new key');

$key = $keys[0];
@ret = keygen($key, 5);
for my $i (0 .. $#ret) {
  test($ret[$i], $keys[$i], "key #$i");
}
test($key, $keys[@ret], 'update new key in list context');

$key = $keys[0];
$ret = keygen($key, 5);
test($ret, $keys[4], 'return last key in scalar context');
test($key, $keys[5], 'update new key in scalar context');

1;
