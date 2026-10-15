use strict;
use warnings;

# Regression test for https://github.com/webpros-cpanel/cpan-crypt-passwd-xs/issues/1
#
# unix_des_crypt($password, undef) used to feed a one-byte empty string literal
# ("") into the DES salt path. cpx_crypt_des() reads both setting[0] and
# setting[1] for old-style (two-character) DES salts, so the second read ran one
# byte past the literal -- a global-buffer-overflow flagged by AddressSanitizer.
#
# The fix normalizes an undef salt to a two-byte NUL string ("\0") so both
# addressable bytes are NUL. This test pins the documented behavior; run it under
# ASAN to confirm the out-of-bounds read no longer occurs:
#
#   ASAN_OPTIONS=detect_leaks=0 LD_PRELOAD=$(gcc -print-file-name=libasan.so) \
#       prove -b t/gh-1.t

use Test::More 'tests' => 2;
use Crypt::Passwd::XS ();

# DES with an undef salt: the exact pattern that triggered the overflow.
is(
    Crypt::Passwd::XS::unix_des_crypt( 'test1234', undef ),
    '',
    'unix_des_crypt with undef salt returns empty string without reading past the salt buffer',
);

# An undef salt with an undef password must not over-read either.
is(
    Crypt::Passwd::XS::unix_des_crypt( undef, undef ),
    '',
    'unix_des_crypt with undef password and undef salt is safe',
);
