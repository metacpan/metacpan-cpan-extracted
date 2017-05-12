use strict;
BEGIN {
  use Test::More;
  use Test::Exception;
  use Test::Deep;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_SQLITE}) {
    plan skip_all => 'TEST_SQLITE not configured';
  } else {
    plan tests => 12;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

my $dbh2 = PgLinkTestUtil::connect_to('TEST_SQLITE');

# remote DDL

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST_SQLITE', 'DROP TABLE IF EXISTS foo')/);
} 'exec: drop table';

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST_SQLITE', 'CREATE TABLE foo(a integer, b text)')/);
} 'exec: create table';

END {
  $dbh2->do('DROP TABLE IF EXISTS foo');
}

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST_SQLITE', 'insert into foo values(?, ?)', 
        ARRAY['999','foo']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: insert 1 row'
  );
} 'exec: insert';

is_deeply(
  $dbh2->selectall_arrayref(q/SELECT * from foo/, {Slice=>{}}),
  [ { a=>999, b=>'foo' } ],
  'exec: row inserted'
);

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST_SQLITE', 'update foo set b=? where a=?', 
        ARRAY['bar','999']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: update 1 row'
  );
} 'exec: update';

is_deeply(
  $dbh2->selectall_arrayref(q/SELECT * from foo/, {Slice=>{}}),
  [ { a=>999, b=>'bar' } ],
  'exec: row updated'
);

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST_SQLITE', 'delete from foo where a=?', 
        ARRAY['999']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: delete 1 row'
  );
} 'exec: delete';

is_deeply(
  $dbh2->selectall_arrayref(q/SELECT * from foo/, {Slice=>{}}),
  [],
  'exec: row deleted'
);

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST_SQLITE', 'nonsense')/);
} qr/syntax error/, 'exec: invalid query';

