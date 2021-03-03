#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/aes_cmac/;

#aes_cmac: test vector from RFC 4493
my $key = '2b7e151628aed2a6abf7158809cf4f3c';

my $msg_1 = '6bc1bee22e409f96e93d7e117393172a';
my $mac_1 = aes_cmac($key, $msg_1, 'aes-128-cbc');
print $mac_1, "\n";
ok($mac_1 eq '07:0A:16:B4:6B:4D:41:44:F7:9B:DD:9D:D0:4A:28:7C');

my $msg_2 = '6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411';
my $mac_2 = aes_cmac($key, $msg_2, 'aes-128-cbc');
print $mac_2, "\n";
ok($mac_2 eq 'DF:A6:67:47:DE:9A:E6:30:30:CA:32:61:14:97:C8:27');

done_testing();
