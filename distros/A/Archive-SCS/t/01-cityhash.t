#!perl
use lib 'lib';
use blib;

use Test2::V0;

use Archive::SCS::CityHash qw(
  cityhash64
  cityhash64_hex
  cityhash64_int
  cityhash64_as_hex
  cityhash64_as_int
);

# No need to worry about 32-bit systems, this dist doesn't build on those anyway
no warnings 'portable';

# Known hash value for the empty string
my $empty_hex = q'9ae16a3b2f90404f';
my $empty_int = 0x9ae16a3b2f90404f;

# The internal hash format is the hex string
my $empty = $empty_hex;

# Produce the internal format
is cityhash64     '',         $empty, 'cityhash64';
is cityhash64_hex $empty_hex, $empty, 'cityhash64_hex';
is cityhash64_int $empty_int, $empty, 'cityhash64_int';

# Convert internal format to usable output
is cityhash64_as_hex $empty, $empty_hex, 'cityhash64_as_hex';
is cityhash64_as_int $empty, $empty_int, 'cityhash64_as_int';

# Non-empty strings
is cityhash64 'def',  '2c6f469efb31c45a', 'low value';
is cityhash64 'ATS/', 'c62abdec6d41f6a6', 'high value';
is cityhash64 'ijkk', '068f019c564fb601', 'zero-padding';

# Long strings use different code paths
is cityhash64 'i' x  9, 'b1256633e4bde42d', 'long string: 9 bytes';
is cityhash64 '1' x 17, '3960b3362f703661', 'long string: 17 bytes';
is cityhash64 '!' x 33, 'da26b9c7ea29c045', 'long string: 33 bytes';
is cityhash64 'A' x 65, 'ded05fac3096aed9', 'long string: 65 bytes';

done_testing;
