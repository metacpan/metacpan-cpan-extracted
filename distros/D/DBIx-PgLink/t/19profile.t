use strict;
use Test::More tests => 3;
use Test::Exception;

use lib 't';
use PgLinkTestUtil;

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

## BUG: can't pass full filepath to ProfileDumper on Windows, path include ':' delimiter

my $profile = "dbi.prof"; # in current server dir

diag "\nProfile will be written in server data directory as '$profile'\n";

ok(
  $dbh->do(q/SELECT dbix_pglink.set_attr(?,?,?,?)/, {},
    'TEST',
    '',
    'Profile', 
    "2/DBI::ProfileDumper/File:$profile"
  ),
  'add attribute'
);

END {
  $dbh->do(q/SELECT dbix_pglink.delete_attr(?,?,?)/, {},
    'TEST',
    '',
    'Profile', 
  );
}

# run some queries
$dbh->do(q/SELECT * FROM test_pg.all_types/);
$dbh->do(q/SELECT * FROM test_pg.crud where id<100/);

# disconnect
$dbh->do(q/SELECT dbix_pglink.disconnect('TEST')/);

SKIP: { skip 'unsolved problem with file flushing', 2;

# use built in function (works only under superuser account!)
# read first 1000 bytes
my $profile_content = $dbh->selectrow_array(q/SELECT pg_read_file(?,?,?)/, {}, 
  $profile,
  0,
  1000 
);

ok($profile_content, 'get file content');

like($profile_content, qr/^DBI::ProfileDumper \d+\.\d/, 'valid profile content');

}

# TODO: unlink dbi.prof?
