use strict;
use Test::More tests => 13;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

# remote DDL

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST', 'DROP TABLE IF EXISTS source.foo')/);
} 'exec: drop table';

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST', 'CREATE TABLE source.foo(a int, b text)')/);
} 'exec: create table';

END {
  $dbh->do(q/DROP TABLE IF EXISTS source.foo/);
}

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST', 'insert into source.foo values(?, ?)', 
        ARRAY['999','foo']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: insert 1 row'
  );
} 'exec: insert';

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from source.foo/, {Slice=>{}}),
  [ { a=>999, b=>'foo' } ],
  'exec: row inserted'
);

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST', 'update source.foo set b=? where a=?', 
        ARRAY['bar','999']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: update 1 row'
  );
} 'exec: update';

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from source.foo/, {Slice=>{}}),
  [ { a=>999, b=>'bar' } ],
  'exec: row updated'
);

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST', 'delete from source.foo where a=?', 
        ARRAY['999']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: delete 1 row'
  );
} 'exec: delete';

is_deeply(
  $dbh->selectall_arrayref(q/SELECT * from source.foo/, {Slice=>{}}),
  [],
  'exec: row deleted'
);

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST', 'nonsense')/);
} qr/execute failed: ERROR:  syntax error/, 'exec: invalid query';


