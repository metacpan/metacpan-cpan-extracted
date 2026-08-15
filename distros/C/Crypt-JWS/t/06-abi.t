#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Crypt::JWS ();

# The table a C consumer would resolve: nonzero pointer, then the
# built-in selftest calls through every core entry the way a consumer
# does (version check, key_from_oct, sign, verify, sha256,
# random_bytes, key_is_private, key_free).
ok Crypt::JWS::_abi_ptr(), '_abi_ptr resolves';
ok Crypt::JWS::_abi_selftest(), 'ABI selftest passes through the table';

done_testing();
