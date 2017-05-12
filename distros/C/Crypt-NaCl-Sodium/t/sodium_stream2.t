
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);

my $crypto_hash = Crypt::NaCl::Sodium->hash();
my $crypto_stream = Crypt::NaCl::Sodium->stream();

my $key = join('', map { chr($_) } 0xdc, 0x90, 0x8d, 0xda, 0x0b, 0x93, 0x44, 0xa9, 0x53, 0x62, 0x9b,
                0x73, 0x38, 0x20, 0x77, 0x88, 0x80, 0xf3, 0xce, 0xb4, 0x21,
                0xbb, 0x61, 0xb9, 0x1c, 0xbd, 0x4c, 0x3e, 0x66, 0x25, 0x6c, 0xe4);

my $nonce = join('', map { chr($_) } 0x82, 0x19, 0xe0, 0x03, 0x6b, 0x7a, 0x0b, 0x37);

my $bytes = $crypto_stream->salsa20_bytes(4194304, $nonce, $key);
my $hash = $crypto_hash->sha256($bytes);
my $hash_hex = bin2hex($hash);

is($hash_hex, "662b9d0e3463029156069b12f918691a98f7dfb2ca0393c96bbfc6b1fbd630a2", "Got expected hash of bytes: $hash_hex");

my $bytes_4000 = substr($bytes, 0, 4000);

my $round1 = $crypto_stream->salsa20_xor_ic($bytes_4000, $nonce, 0, $key);
like($round1, qr/^\0+$/, "xor_ic as expected");

my $round2 = $crypto_stream->salsa20_xor_ic($round1, $nonce, 1, $key);
my $sbytes = "$bytes";
substr($sbytes, 0, 4000, $round2);
$hash = $crypto_hash->sha256($sbytes);
$hash_hex = $hash->to_hex;

is($hash_hex, "0cc9ffaf60a99d221b548e9762385a231121ab226d1c610d2661ced26b6ad5ee", "Got expected hash of bytes: $hash_hex");


done_testing();

