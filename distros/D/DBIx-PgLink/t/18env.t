use strict;
use Test::More tests => 3;
use Test::Exception;

use lib 't';
use PgLinkTestUtil;

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

ok(
  $dbh->do(q/SELECT dbix_pglink.set_role('TEST','','Connector','Environment',NULL,'f')/),
  'add env role'
);

ok(
  $dbh->do(q/SELECT dbix_pglink.set_env(?,?,?,?,?)/, {},
    'TEST', # conn
    '',     # global
    'set',  # action
    'FOO',  # name
    'bar'   # value
  ),
  'add env variable'
);

END {
  $dbh->do(q/SELECT dbix_pglink.delete_role('TEST','','Connector','Environment'::text)/),
  $dbh->do(q/SELECT dbix_pglink.delete_env(?,?,?)/, {},
    'TEST',
    '', # global
    'FOO', 
  );
}

$dbh->do(<<'END_OF_SQL');
create or replace function test_env(_name text)
returns text language plperlu as $body$
  my $name = shift;
  return $ENV{$name};
$body$;
END_OF_SQL

# do any remote query
$dbh->do(q/SELECT dbix_pglink.exec('TEST','SELECT 1')/);

is(
  scalar($dbh->selectrow_array(q/SELECT test_env('FOO')/)),
  'bar',
  'variable is set'
);
