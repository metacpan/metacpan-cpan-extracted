use strict;
use warnings;

use Crypt::ScryptKDF;
use Test::More;

my @opts = (8, 1, 1, 5);
is( Crypt::ScryptKDF::scrypt_b64("", "", @opts), "H/7KqYA=" );

### 6 args
is( Crypt::ScryptKDF::scrypt_raw("p", "s", @opts), pack("H*", "a0d686e921"));
is( Crypt::ScryptKDF::scrypt_hex("p", "s", @opts), "a0d686e921" );
is( Crypt::ScryptKDF::scrypt_b64("p", "s", @opts), "oNaG6SE=" );
is( Crypt::ScryptKDF::scrypt_hash("p", "s", @opts), "SCRYPT:8:1:1:cw==:oNaG6SE=" );

### 5 args
@opts = (16, 1, 1, 151);
like( Crypt::ScryptKDF::scrypt_hash("test", @opts), qr/^SCRYPT:\d+:\d+:\d+:.{10,}:.{10,}/);

### 2 args
is( Crypt::ScryptKDF::scrypt_raw("passwd", "salt"), pack("H*", "13cbf0adb6647def0463c6696633b686da0987c01646bdfd65f32c2fd90e4d38"));
is( Crypt::ScryptKDF::scrypt_hex("passwd", "salt"), "13cbf0adb6647def0463c6696633b686da0987c01646bdfd65f32c2fd90e4d38" );
is( Crypt::ScryptKDF::scrypt_b64("passwd", "salt"), "E8vwrbZkfe8EY8ZpZjO2htoJh8AWRr39ZfMsL9kOTTg=" );
is( Crypt::ScryptKDF::scrypt_hash("passwd", "salt"), "SCRYPT:16384:8:1:c2FsdA==:E8vwrbZkfe8EY8ZpZjO2htoJh8AWRr39ZfMsL9kOTTg=" );

### 1 args
like( Crypt::ScryptKDF::scrypt_hash("passwd"), qr/^SCRYPT:\d+:\d+:\d+:.{10,}:.{10,}/);

my $str = Crypt::ScryptKDF::scrypt_hash("passwd");
is( Crypt::ScryptKDF::scrypt_hash_verify("passwd", $str), 1);

like( Crypt::ScryptKDF::scrypt_hash("passwd",\4),  qr/^SCRYPT:\d+:\d+:\d+:.{8}:.{10,}/);
like( Crypt::ScryptKDF::scrypt_hash("passwd",\8),  qr/^SCRYPT:\d+:\d+:\d+:.{12}:.{10,}/);
like( Crypt::ScryptKDF::scrypt_hash("passwd",\16), qr/^SCRYPT:\d+:\d+:\d+:.{24}:.{10,}/);
like( Crypt::ScryptKDF::scrypt_hash("passwd",\32), qr/^SCRYPT:\d+:\d+:\d+:.{44}:.{10,}/);

done_testing;