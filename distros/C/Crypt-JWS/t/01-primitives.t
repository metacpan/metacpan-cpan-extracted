#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Crypt::JWS qw(sha256 sha384 sha512 hmac_sha256 hmac_sha384 hmac_sha512
                  b64url b64url_decode ct_eq random_bytes);

# SHA-2 known answers (NIST, "abc")
is unpack('H*', sha256('abc')),
   'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
   'sha256 abc';
is unpack('H*', sha384('abc')),
   'cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed'
 . '8086072ba1e7cc2358baeca134c825a7',
   'sha384 abc';
is unpack('H*', sha512('abc')),
   'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a'
 . '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f',
   'sha512 abc';

# HMAC known answers (RFC 4231 test case 2: key "Jefe", data
# "what do ya want for nothing?")
is unpack('H*', hmac_sha256('Jefe', 'what do ya want for nothing?')),
   '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
   'hmac_sha256 rfc4231 tc2';
is unpack('H*', hmac_sha384('Jefe', 'what do ya want for nothing?')),
   'af45d2e376484031617f78d2b58a6b1b9c7ef464f5a01b47e42ec3736322445e'
 . '8e2240ca5e69e2c78b3239ecfab21649',
   'hmac_sha384 rfc4231 tc2';
is unpack('H*', hmac_sha512('Jefe', 'what do ya want for nothing?')),
   '164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea250554'
 . '9758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737',
   'hmac_sha512 rfc4231 tc2';

# base64url
is b64url(''), '', 'b64url empty';
is b64url('f'), 'Zg', 'b64url 1 byte, unpadded';
is b64url('fo'), 'Zm8', 'b64url 2 bytes';
is b64url('foo'), 'Zm9v', 'b64url 3 bytes';
is b64url("\xfb\xff"), '-_8', 'url-safe alphabet';
is b64url_decode('Zm9v'), 'foo', 'decode';
is b64url_decode('Zm8='), 'fo', 'decode tolerates padding';
is b64url_decode('-_8'), "\xfb\xff", 'decode url alphabet';
is b64url_decode('+/8'), "\xfb\xff", 'decode standard alphabet too';
for my $round (1 .. 50) {
    my $bytes = random_bytes(1 + int rand 64);
    is b64url_decode(b64url($bytes)), $bytes, "roundtrip $round"
        or last;
}
ok !eval { b64url_decode('a b'); 1 }, 'space rejected';
ok !eval { b64url_decode('a'); 1 }, 'lone char rejected';

# ct_eq
ok ct_eq('same', 'same'), 'ct_eq equal';
ok !ct_eq('same', 'sama'), 'ct_eq differ';
ok !ct_eq('same', 'samee'), 'ct_eq length differ';
ok ct_eq('', ''), 'ct_eq empty';

# random_bytes
is length random_bytes(32), 32, 'random_bytes length';
isnt random_bytes(32), random_bytes(32), 'random_bytes vary';
ok !eval { random_bytes(0); 1 }, 'zero rejected';

done_testing();
