use v5.28;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package Archive::SCS::CityHash 1.01;

use Exporter 'import';
use XSLoader 0.14;

XSLoader::load();


BEGIN {
  our @EXPORT_OK = qw(
    cityhash64
    cityhash64_int
    cityhash64_hex
    cityhash64_bin
    cityhash64_as_hex
    cityhash64_as_int
  );
}


# Input: the original file path as a string
# Output: the internal format
sub cityhash64 :prototype($) ($path) {
  cityhash64_($path)
}


# Input: the hash as integer
# Output: the internal format
sub cityhash64_int :prototype($) ($hash_int) {
  pack 'Q>', $hash_int
}


# Input: the hash as 8-byte binary string scalar
# Output: the internal format
sub cityhash64_bin :prototype($) ($hash_bin) {
  $hash_bin
}


# Input: the hash as 16-byte hex-encoded string scalar
# Output: the internal format
sub cityhash64_hex :prototype($) ($hash_hex) {
  pack 'H*', $hash_hex;
}


# Input: the internal format
# Output: the hash as 16-byte hex-encoded string scalar (human-readable)
sub cityhash64_as_hex :prototype($) ($hash) {
  unpack 'H*', $hash;
}


# Input: the internal format
# Output: the hash as integer
sub cityhash64_as_int :prototype($) ($hash) {
  unpack 'Q>', $hash;
}


# The "internal format" of the hash is currently an 8-byte binary PV.

1;
