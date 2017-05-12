#!/ust/bin/env perl

use strict;
use warnings;
use Test::More tests => 16;
BEGIN { use_ok('Crypt::OpenSSL::Blowfish::CFB64') };

my ($c1,$c2,$c3);
ok $c1 = Crypt::OpenSSL::Blowfish::CFB64->new("sample"), 'crypt with key';
ok $c2 = Crypt::OpenSSL::Blowfish::CFB64->new("sample", pack(C8 => (0)x8)), 'crypt with key and zero';
ok $c3 = Crypt::OpenSSL::Blowfish::CFB64->new("sample", pack(C8 => 1..8)), 'crypt with key and 1..8';

is $c1->encrypt_hex("test"),"fcdf17c5", "encrypt key (test)";
is $c2->encrypt_hex("test"),"fcdf17c5", "encrypt key+zero (test)";
is $c3->encrypt_hex("test"),"45213941", "encrypt key+1..8 (test)";

is $c1->decrypt(pack 'H*', "fcdf17c5"),"test", "decrypt key (test)";
is $c1->decrypt_hex("fcdf17c5"),"test",        "decrypt_hex key (test)";

is $c2->decrypt(pack 'H*', "fcdf17c5"),"test", "decrypt key+zero (test)";
is $c2->decrypt_hex("fcdf17c5"),"test",        "decrypt_hex key+zero (test)";

is $c3->decrypt(pack 'H*', "45213941"),"test", "decrypt key+1..8 (test)";
is $c3->decrypt_hex("45213941"),"test",        "decrypt_hex key+1..8 (test)";

# Recreate objects and try again

is $c2->decrypt( $c1->encrypt("test") ), "test", 'dec1/enc2';
is $c1->decrypt( $c2->encrypt("test") ), "test", 'dec2/enc1';
is $c3->decrypt( $c3->encrypt("test") ), "test", 'dec3/enc3';

