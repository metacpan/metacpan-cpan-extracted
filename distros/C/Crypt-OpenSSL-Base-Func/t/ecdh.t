#!/usr/bin/perl
use utf8;
use strict;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/ecdh/;
use FindBin;

my $z = ecdh("$FindBin::Bin/x25519_a_priv.pem", "$FindBin::Bin/x25519_b_pub.pem");
print $z, "\n";
ok($z eq "0D:66:1C:30:3E:A0:35:BE:29:36:17:4F:EC:09:54:21:3D:0D:7C:76:0F:67:B9:B6:61:41:40:64:30:4A:83:47");

my $z2 = ecdh("$FindBin::Bin/x25519_b_priv.pem", "$FindBin::Bin/x25519_a_pub.pem");
print $z2, "\n";
ok($z2 eq $z);

done_testing();
