#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/PKCS5_PBKDF2_HMAC/;

my $pbkdf2_key = PKCS5_PBKDF2_HMAC('123456', 'b698314b0d68bcbd', 2048, 'sha256', 32);
print $pbkdf2_key, "\n";
ok($pbkdf2_key eq 'F6:8B:53:86:DE:3A:8D:63:35:84:69:50:54:4D:29:A5:5A:D3:32:8D:EA:17:68:53:04:D7:82:28:48:AE:C5:34');

done_testing();
