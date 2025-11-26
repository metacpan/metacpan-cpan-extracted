use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':hash';

my $str = "hello";
# validate with sha512sum or whatever
my $expected = "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043";

my $hash = hash($str);
ok($hash, "hash generated output");
is(length($hash), hash_BYTES, "hash correct length");
is(unpack("H*", $hash), $expected, "hash correct output");

done_testing();
