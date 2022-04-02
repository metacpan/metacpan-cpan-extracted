#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/PKCS12_key_gen/;

my $macdata_key = PKCS12_key_gen('123456', pack("H*", 'e241f01650dbeae4'), 3, 2048, 32, 'sha256');
print unpack("H*", $macdata_key), "\n";
is(unpack("H*", $macdata_key), '721259f14aad70b58839f71566b433da1b8ad08f650f4d02faaa0b9b095bb51d', 'PKCS12_key_gen');
#ok($macdata_key eq '72:12:59:F1:4A:AD:70:B5:88:39:F7:15:66:B4:33:DA:1B:8A:D0:8F:65:0F:4D:02:FA:AA:0B:9B:09:5B:B5:1D');

done_testing();
