
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);

my $crypto_hash = Crypt::NaCl::Sodium->hash();
my $crypto_stream = Crypt::NaCl::Sodium->stream();

my $key = join('', map { chr($_) } 0x1b, 0x27, 0x55, 0x64, 0x73, 0xe9, 0x85, 0xd4, 0x62, 0xcd, 0x51,
        0x19, 0x7a, 0x9a, 0x46, 0xc7, 0x60, 0x09, 0x54, 0x9e, 0xac, 0x64,
        0x74, 0xf2, 0x06, 0xc4, 0xee, 0x08, 0x44, 0xf6, 0x83, 0x89 );

my $nonce = join('', map { chr($_) } 0x69, 0x69, 0x6e, 0xe9, 0x55, 0xb6, 0x2b, 0x73,
                            0xcd, 0x62, 0xbd, 0xa8, 0x75, 0xfc, 0x73, 0xd6,
                            0x82, 0x19, 0xe0, 0x03, 0x6b, 0x7a, 0x0b, 0x37 );

my $bytes = $crypto_stream->bytes(4194304, $nonce, $key);
my $hash = $crypto_hash->sha256($bytes);
my $hash_hex = $hash->to_hex;

is($hash_hex, "662b9d0e3463029156069b12f918691a98f7dfb2ca0393c96bbfc6b1fbd630a2", "Got expected hash of bytes: $hash_hex");

my $bytes_4000 = substr($bytes, 0, 4000);

my $round1 = $crypto_stream->xor_ic($bytes_4000, $nonce, 0, $key);
like($round1, qr/^\0+$/, "xor_ic as expected");

my $round2 = $crypto_stream->xor_ic($round1, $nonce, 1, $key);
my $sbytes = "$bytes";
substr($sbytes, 0, 4000, $round2);
$hash = $crypto_hash->sha256($sbytes);
$hash_hex = $hash->to_hex;

is($hash_hex, "0cc9ffaf60a99d221b548e9762385a231121ab226d1c610d2661ced26b6ad5ee", "Got expected hash of bytes: $hash_hex");


done_testing();

