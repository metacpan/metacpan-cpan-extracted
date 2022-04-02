#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/aes_cmac/;

#aes_cmac: test vector from RFC 4493
my $key = pack("H*", '2b7e151628aed2a6abf7158809cf4f3c');

my $msg_1 = pack("H*", '6bc1bee22e409f96e93d7e117393172a');
my $mac_1 = aes_cmac($key, $msg_1, 'aes-128-cbc');
$mac_1 = unpack("H*", $mac_1);
print $mac_1, "\n";
is($mac_1, '070a16b46b4d4144f79bdd9dd04a287c', 'aes_cmac');

my $msg_2 = pack("H*", '6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411');
my $mac_2 = aes_cmac($key, $msg_2, 'aes-128-cbc');
$mac_2 = unpack("H*", $mac_2);
print $mac_2, "\n";
is($mac_2, 'dfa66747de9ae63030ca32611497c827', 'aes_cmac');




done_testing();
