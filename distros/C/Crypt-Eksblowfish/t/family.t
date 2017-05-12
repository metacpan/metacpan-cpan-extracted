use warnings;
use strict;

use Test::More tests => 2 + 26*10;

BEGIN { use_ok "Crypt::Eksblowfish::Family"; }

eval { "Crypt::Eksblowfish::Family"->new("a"x16) };
like $@, qr/Crypt::Eksblowfish::Family::new is not a class method/;

while(<DATA>) {
	my($cost, @data) = split;
	my($salt, $pt, $ct, $key) = map { pack("H*", $_) } @data;
	my $family = Crypt::Eksblowfish::Family->new_family($cost, $salt);
	ok $family;
	ok $family->can("keysize");
	ok $family->can("encrypt");
	is $family->cost, $cost;
	is $family->salt, $salt;
	is $family->blocksize, 8;
	is $family->keysize, 0;
	eval { $family->encrypt($pt) };
	like $@, qr/\ACrypt::Eksblowfish::Family::encrypt called/;
	my $cipher = $family->new($key);
	ok $cipher;
	is $cipher->blocksize, 8;
	is $cipher->encrypt($pt), $ct;
	is $cipher->decrypt($ct), $pt;
	my $pkg = $family->as_class;
	like $pkg, qr/\ACrypt::Eksblowfish::Family::/;
	is $pkg, $family->as_class;
	eval { $pkg->new_family($cost, $salt) };
	like $@, qr/\A${pkg}->new_family called/;
	ok $pkg->can("keysize");
	ok $pkg->can("encrypt");
	is $pkg->cost, $cost;
	is $pkg->salt, $salt;
	is $pkg->blocksize, 8;
	is $pkg->keysize, 0;
	$cipher = $pkg->new($key);
	ok $cipher;
	is $cipher->blocksize, 8;
	is $cipher->encrypt($pt), $ct;
	is $cipher->decrypt($ct), $pt;
	is $pkg->as_class, $pkg;
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
