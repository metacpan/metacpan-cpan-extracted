use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Crypt/NaCl/Sodium.pm',
    'lib/Crypt/NaCl/Sodium/aead.pod',
    'lib/Crypt/NaCl/Sodium/auth.pod',
    'lib/Crypt/NaCl/Sodium/box.pod',
    'lib/Crypt/NaCl/Sodium/generichash.pod',
    'lib/Crypt/NaCl/Sodium/hash.pod',
    'lib/Crypt/NaCl/Sodium/onetimeauth.pod',
    'lib/Crypt/NaCl/Sodium/pwhash.pod',
    'lib/Crypt/NaCl/Sodium/scalarmult.pod',
    'lib/Crypt/NaCl/Sodium/secretbox.pod',
    'lib/Crypt/NaCl/Sodium/shorthash.pod',
    'lib/Crypt/NaCl/Sodium/sign.pod',
    'lib/Crypt/NaCl/Sodium/stream.pod',
    'lib/Data/BytesLocker.pod'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
