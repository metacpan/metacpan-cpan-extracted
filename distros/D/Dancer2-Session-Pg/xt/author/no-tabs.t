use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dancer2/Session/Pg.pm',
    'lib/Dancer2/Session/Pg/Cipher.pm',
    'lib/Dancer2/Session/Pg/Cipher/AESGCM.pm',
    'lib/Dancer2/Session/Pg/Cipher/ChaCha20Poly1305.pm',
    't/cipher.t',
    't/concurrency.t',
    't/dancer2_app.t',
    't/lib/SessionPgTest/Ddl.pm',
    't/lib/SessionPgTest/PgDB.pm',
    't/session_pg.t',
    't/stored_format.t'
);

notabs_ok($_) foreach @files;
done_testing;
