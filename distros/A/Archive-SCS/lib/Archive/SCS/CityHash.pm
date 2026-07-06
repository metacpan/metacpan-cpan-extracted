use v5.28;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package Archive::SCS::CityHash 1.12;

use Exporter 'import';
use XSLoader 0.14;

XSLoader::load();


BEGIN {
  our @EXPORT_OK = qw(
    cityhash64
    cityhash64_int
    cityhash64_hex
    cityhash64_as_hex
    cityhash64_as_int
  );
}


# Input: the original file path as a string
# Output: the internal format
sub cityhash64 :prototype($) ($path) {
  sprintf '%016x', cityhash64_($path)
}


# Input: the hash as integer
# Output: the internal format
sub cityhash64_int :prototype($) ($hash_int) {
  sprintf '%016x', $hash_int
}


# Input: the hash as 16-byte hex-encoded string scalar
# Output: the internal format
sub cityhash64_hex :prototype($) ($hash_hex) {
  $hash_hex
}


# Input: the internal format
# Output: the hash as 16-byte hex-encoded string scalar (human-readable)
sub cityhash64_as_hex :prototype($) ($hash) {
  $hash
}


# Input: the internal format
# Output: the hash as integer
sub cityhash64_as_int :prototype($) ($hash) {
  # No need to worry about 32-bit systems, this dist doesn't build on those anyway
  no warnings 'portable';
  hex $hash
}


# The "internal format" of the hash is a 16-byte hex PV in network byte order.

1;
