use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
