use strict;
use warnings;

# Regression test for https://github.com/webpros-cpanel/cpan-crypt-passwd-xs/issues/7
#
# cpx_crypt_des() handles an "old"-style (two-character) DES salt by reading
# setting[0] and setting[1]. The setting[1] read at des.c:684 was unconditional,
# so a *defined* empty-string salt ("") -- whose buffer is a single NUL byte --
# caused a one-byte out-of-bounds read past the end of the salt buffer. This is
# the sibling of GH #1, which normalized only an *undef* salt to a two-byte
# NUL string ("\0") and so did not cover a defined empty string passed straight
# through as an SvPOK scalar.
#
# The fix guards the setting[1] read on setting[0] being non-NUL, so an empty
# salt never reads past its terminating NUL.
#
# NOTE: like t/gh-1.t and t/gh-5.t this is a *behavioral* regression guard. Through
# Perl the over-read lands in SV buffer slack, so it will not by itself trip a
# memory checker on the unfixed code. The out-of-bounds read is reproduced
# directly against the C entry point (cpx_crypt_des) with an exact-size 1-byte
# heap buffer, where valgrind flags a read past the salt at des.c:684 on the
# unfixed code and exits clean after the fix; see GH #7 for the reproduction.

use Test::More 'tests' => 3;
use Crypt::Passwd::XS ();

# Defined empty-string salt: the exact pattern that triggered the over-read.
# It is treated like an empty salt and yields an empty string, matching the
# undef-salt behavior pinned by t/gh-1.t -- but without reading past the buffer.
is(
    Crypt::Passwd::XS::unix_des_crypt( 'test1234', '' ),
    '',
    'unix_des_crypt with defined empty-string salt is safe (no read past the salt buffer)',
);

# Undef password with a defined empty-string salt must not over-read either.
is(
    Crypt::Passwd::XS::unix_des_crypt( undef, '' ),
    '',
    'unix_des_crypt with undef password and empty-string salt is safe',
);

# The valid old-style path must still hash correctly -- the fix must not regress it.
is(
    Crypt::Passwd::XS::unix_des_crypt( 'test1234', 'ab' ),
    'abP/cckPJaUqA',
    'unix_des_crypt with a well-formed two-character salt still produces the expected hash',
);
