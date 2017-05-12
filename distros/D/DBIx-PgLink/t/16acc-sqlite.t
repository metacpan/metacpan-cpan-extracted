use strict;

BEGIN {
  use Test::More;
  use Test::Exception;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_SQLITE}) {
    plan skip_all => 'TEST_SQLITE not configured';
  } else {
    plan tests => 10;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();
my $dbh2 = PgLinkTestUtil::connect_to('TEST_SQLITE');

sub get_row {
  $dbh->selectrow_hashref('SELECT * FROM test_sqlite.crud WHERE id=?', {}, shift);
}

lives_ok {
  $dbh->do(q/delete from test_sqlite.crud where id=100/);
} 'remote delete';

is_deeply(get_row(100), undef, 'remote select 1');

throws_ok {
  $dbh->do(q/insert into test_sqlite.crud(id, t) values (1, 'remote insert')/);
} qr/PRIMARY KEY must be unique/, 'remote insert (constraint violation)';

is_deeply(get_row(100), undef, 'remote select 2');

lives_ok {
  $dbh->do(q/insert into test_sqlite.crud(id, i,t) select 100, 100, 'remote insert'/);
} 'remote insert';

is_deeply(get_row(100), {id=>100, i=>100, t=>'remote insert'}, 'remote select 3');

lives_ok {
  $dbh->do(q/update test_sqlite.crud set i=777 where id=100/);
} 'remote update';

is_deeply(get_row(100), {id=>100, i=>777, t=>'remote insert'}, 'remote select 4');


lives_ok {
  $dbh2->do('DELETE FROM all_types');
  $dbh2->do('INSERT INTO all_types(f_integer, f_real, f_text, f_blob, f_date) VALUES(?,?,?,?,?)', {}, 
    12345,
    1.2345e67,
    'foo',
    "abc\000\377def",
    '2007-12-31',
  );
} 'direct fill all_types';

is_deeply (
  $dbh->selectall_arrayref(q/SELECT * FROM test_sqlite.all_types/, {Slice=>{}}),
  [{
    f_integer => 12345,
    f_real => 1.2345e67, 
    f_text => 'foo', 
    f_blob => "abc\000\377def", 
    f_date => '2007-12-31',
  }],
 'remote select from all_types'
);

