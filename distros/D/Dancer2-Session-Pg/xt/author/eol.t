use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
