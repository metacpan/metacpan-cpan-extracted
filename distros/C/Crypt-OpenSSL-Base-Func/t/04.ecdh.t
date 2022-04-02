#!/usr/bin/perl
use utf8;
use strict;
use Test::More;
use Crypt::OpenSSL::Base::Func qw/ecdh/;
use FindBin;

my $z = ecdh("$FindBin::Bin/x25519_a_priv.pem", "$FindBin::Bin/x25519_b_pub.pem");
$z = unpack("H*", $z);
print $z, "\n";
is($z, '0d661c303ea035be2936174fec0954213d0d7c760f67b9b661414064304a8347', 'ecdh');

my $z2 = ecdh("$FindBin::Bin/x25519_b_priv.pem", "$FindBin::Bin/x25519_a_pub.pem");
$z2 = unpack("H*", $z2);
print $z2, "\n";
is($z, $z2, 'ecdh');

done_testing();
