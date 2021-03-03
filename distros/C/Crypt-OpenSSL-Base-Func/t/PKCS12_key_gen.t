#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/PKCS12_key_gen/;

my $macdata_key = PKCS12_key_gen('123456', 'e241f01650dbeae4', 3, 2048, 32, 'sha256');
print $macdata_key, "\n";
ok($macdata_key eq '72:12:59:F1:4A:AD:70:B5:88:39:F7:15:66:B4:33:DA:1B:8A:D0:8F:65:0F:4D:02:FA:AA:0B:9B:09:5B:B5:1D');

done_testing();
