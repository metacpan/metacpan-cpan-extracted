use strict;
use warnings;
use Test::More;
use Crypt::NaCl::Tweet ':box';

# randomly generated. DO NOT USE.
# bad_* have first or last nybble altered.
my $pk1 = pack('H*', '0ae826ad2a26bb965202f4ae557db1cb271d73742b85ef0941a655e63d43b451');
my $bad_pk1 = pack('H*', '5ae826ad2a26bb965202f4ae557db1cb271d73742b85ef0941a655e63d43b451');
my $sk1 = pack('H*', 'c32d777a20c8dc0647cad9fe729875aae6f5ac02c3e7b7a3ef6e30d25e67b47f');
my $pk2 = pack('H*', 'a14ad92dc89b7361a04fd01edf8f140142438407283f3b94ab23be88d65c4a6e');
my $sk2 = pack('H*', 'a11eb02985afeeebdcaebcb29036a677688f7015ce2024af5e1cbe073d46d90a');
my $bad_sk2 = pack('H*', 'a11eb02985afeeebdcaebcb29036a677688f7015ce2024af5e1cbe073d46d905');

my $key1 = box_beforenm($pk1, $sk2);
ok($key1, "beforenm key generated");
my $key2 = box_beforenm($pk2, $sk1);
is(unpack('H*', $key1), unpack('H*', $key2), "beforenm same keys either side of key pair");
my $bad_key1 = box_beforenm($bad_pk1, $sk2);
isnt(unpack('H*', $bad_key1), unpack('H*', $key1), "beforenm bad pk doesn't match good");
my $bad_key2 = box_beforenm($pk1, $bad_sk2);
isnt(unpack('H*', $bad_key2), unpack('H*', $key1), "beforenm bad sk doesn't match good");

my $str = "secret secrets are no fun";
my $nonce = "\0" x 24;

my $ct = box_afternm($str, $nonce, $key1);
ok($ct, "afternm ciphertext generated");
is(length($ct), length($str) + box_ZEROBYTES, "afternm ciphertext correct length");
isnt($str, $ct, "afternm ciphertext does not match input");

my $pt = box_open_afternm($ct, $nonce, $key1);
ok($pt, "open_afternm generated plaintext");
isnt($pt, $ct, "open_afternm plaintext does not match ciphertext");
is($pt, $str, "open_afternm plaintext roundtripped");
ok(!defined(box_open_afternm($ct, $nonce, $bad_key1)), "open_afternm bad key fails decrypting");

done_testing();
