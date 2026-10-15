use strict;
use warnings;

# Regression test for https://github.com/webpros-cpanel/cpan-crypt-passwd-xs/issues/5
#
# cpx_crypt_des() parses "new"-style ('_'-prefixed) DES salts by reading
# setting[1..8] for the count and salt fields. Those reads were unconditional,
# and cpx_ascii_to_bin() does not stop at a NUL terminator, so a new-style salt
# shorter than 9 bytes (e.g. "_") caused an out-of-bounds read past the end of
# the salt buffer (des.c:626-630). This is the new-style sibling of GH #1, which
# only fixed the old-style two-byte path.
#
# The fix bounds both parse loops by strlen(setting) so no byte past the salt's
# NUL is ever read.
#
# NOTE: this .t is a *behavioral* regression guard -- it pins safe, deterministic
# output for short/empty new-style salts. It will NOT by itself trip a memory
# checker on the unfixed code, because Perl's SV string buffers carry allocation
# slack past the logical end, so the over-read lands in that slack rather than
# off the end of the malloc'd region. The out-of-bounds read is reproduced
# directly against the C entry point (cpx_crypt_des) with an exact-size heap
# buffer, where valgrind flags reads past the salt at des.c:627/630 on the
# unfixed code; see https://github.com/webpros-cpanel/cpan-crypt-passwd-xs/issues/5
# for the reproduction recipe.

use Test::More 'tests' => 5;
use Crypt::Passwd::XS ();

# A bare "_" is a new-style prefix with no count/salt bytes. Parsing it must not
# read past the one-byte salt. count ends up 0, so the DES core reports an error
# and we get undef -- but safely, with no over-read.
is(
    Crypt::Passwd::XS::unix_des_crypt( 'test1234', '_' ),
    undef,
    'unix_des_crypt with bare "_" new-style salt is safe (no read past the salt buffer)',
);

# Same path reached through the prefix-dispatching crypt(): "_" has no '$', so it
# routes to DES.
is(
    Crypt::Passwd::XS::crypt( 'test1234', '_' ),
    undef,
    'crypt() dispatch to DES with bare "_" salt is safe',
);

# A short-but-nonempty new-style salt: the count loop stops at the NUL and the
# salt loop must not start reading at offset 5 past the end of the buffer.
is(
    Crypt::Passwd::XS::unix_des_crypt( 'test1234', '_abc' ),
    '_abcCmA31x4fWSA',
    'unix_des_crypt with short new-style salt "_abc" is safe and deterministic',
);

# A full, well-formed new-style salt must still hash correctly -- the fix must
# not regress the valid path.
is(
    Crypt::Passwd::XS::unix_des_crypt( 'test1234', '_J9..rasm' ),
    '_J9..rasmGcZhTFQu4Vk',
    'unix_des_crypt with full new-style salt "_J9..rasm" still produces the expected hash',
);

# Undef password with a new-style salt must not over-read either.
is(
    Crypt::Passwd::XS::unix_des_crypt( undef, '_' ),
    undef,
    'unix_des_crypt with undef password and "_" salt is safe',
);
