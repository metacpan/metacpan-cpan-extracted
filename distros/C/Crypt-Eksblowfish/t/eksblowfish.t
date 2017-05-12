use warnings;
use strict;

use Test::More tests => 12 + 6*11;

BEGIN { use_ok "Crypt::Eksblowfish"; }

is(Crypt::Eksblowfish->blocksize, 8);

eval { Crypt::Eksblowfish->new(-1, "a" x 16, "abcd") }; isnt $@, "";
eval { Crypt::Eksblowfish->new(0, "a" x 15, "abcd") }; isnt $@, "";
eval { Crypt::Eksblowfish->new(0, "a" x 17, "abcd") }; isnt $@, "";
eval { Crypt::Eksblowfish->new(0, "a" x 16, "") }; isnt $@, "";
eval { Crypt::Eksblowfish->new(0, "a" x 16, "a") }; is $@, "";
eval { Crypt::Eksblowfish->new(0, "a" x 16, "a" x 72) }; is $@, "";
eval { Crypt::Eksblowfish->new(0, "a" x 16, "a" x 73) }; isnt $@, "";

my $cipher = Crypt::Eksblowfish->new(0, "a" x 16, "abcd");
ok $cipher;
is $cipher->p_array->[2], 0x7653a00a;
is $cipher->s_boxes->[2]->[222], 0xee8053dc;

while(<DATA>) {
	my($cost, @data) = split;
	my($salt, $pt, $ct, $key) = map { pack("H*", $_) } @data;
	my $cipher = Crypt::Eksblowfish->new($cost, $salt, $key);
	ok $cipher;
	is ref($cipher), "Crypt::Eksblowfish";
	is $cipher->blocksize, 8;
	is $cipher->encrypt($pt), $ct;
	is $cipher->decrypt($ct), $pt;
	is !!$cipher->is_weak, $key eq pack("H*", "67df71d0acdcbef5");
}

1;

__DATA__
0 77b5a8e66bf437f3d03cc6b4cdc7d429 5bb0131eefeb17f7 3f6fdaddcd605c01 13ffc413d7ed649a8551
1 cfd2fe88ead6a5a8dca9523889081f39 ea936213788e916d 0999967ad37fcca1 af5d
2 31188a1d6e1d65b3f71b86bce55a67f4 90ee362f71522361 8217921bcf1deaa3 c8931a6e0efb32937b68
3 d2f0d334b90b356d592c3019ec8eca71 071147d03942894d 2343bba87456e218 0e8c8f04c67af0b2c348
4 9727d95b6d12343ef1411edc0a6ebf1d 59d4a5de34d29cb6 427895b5c7743cf8 e1278612
5 171125170554d7bd6e712fdcc549c00d cb78660a68b67ab9 dfd346f724ddb9c7 0527bb76250e8e606129
6 4b3916adb70a841658aaf4ec7ebb51e8 7ba6a4ca4d6bcc29 325ac35c6b7eb748 7bda
7 d05f3e37e0abb779485cb0c42d4898b2 9fade3ceb8780bdb 38b574199128a028 0365bd0af501
8 e1aedf7b96277f44bf7ee57abe2ad0c4 099845e9998a5d66 ccbdfdd5dd8243eb 3c2dae71
9 0bc4788fa499faac1e54e6c8d3c492d8 bffb573ea1a50827 b663a0daeaf7db86 32711230b5b1ce
0 632883779720f1b6a8cb65f9526e638f e1b46bade19d63d5 597cde1ed988cc79 67df71d0acdcbef5
