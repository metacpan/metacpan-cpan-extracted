#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::PKCS::Func qw/PKCS12_key_gen PKCS5_PBKDF2_HMAC/;

my $macdata_key = PKCS12_key_gen('123456', 'e241f01650dbeae4', 3, 2048, 32, 'sha256');
print $macdata_key, "\n";
ok($macdata_key eq '72:12:59:F1:4A:AD:70:B5:88:39:F7:15:66:B4:33:DA:1B:8A:D0:8F:65:0F:4D:02:FA:AA:0B:9B:09:5B:B5:1D');

my $pbkdf2_key = PKCS5_PBKDF2_HMAC('123456', 'b698314b0d68bcbd', 2048, 'sha256', 32);
print $pbkdf2_key, "\n";
ok($pbkdf2_key eq 'F6:8B:53:86:DE:3A:8D:63:35:84:69:50:54:4D:29:A5:5A:D3:32:8D:EA:17:68:53:04:D7:82:28:48:AE:C5:34');

done_testing();
