use strict;

BEGIN {
  use Test::More;
  use Test::Exception;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_XBASE}) {
    plan skip_all => 'TEST_XBASE not configured';
  } else {
    plan tests => 12;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

sub get_row {
  $dbh->selectrow_hashref('SELECT * FROM test_xbase.crud WHERE "ID"=?', {}, @_);
}

lives_ok {
  $dbh->do(q/delete from test_xbase.crud where "ID"=100/);
} 'remote delete';

is_deeply(get_row(100), undef, 'remote select 1');

lives_ok {
  $dbh->do(q/insert into test_xbase.crud("T") select 'remote insert'/);
} 'remote insert (no constraints)';

is_deeply(get_row(100), undef, 'remote select 2');

lives_ok {
  $dbh->do(q/insert into test_xbase.crud("ID", "I","T") select 100, 100, 'remote insert'/);
} 'remote insert';

is_deeply(get_row(100), {ID=>100, I=>100, T=>'remote insert'}, 'remote select 3');

lives_ok {
  $dbh->do(q/update test_xbase.crud set "I"=777 where "ID"=100/);
} 'remote update';

is_deeply(get_row(100), {ID=>100, I=>777, T=>'remote insert'}, 'remote select 4');

# ------------- date conversion

lives_ok {
  $dbh->do(q/update test_xbase.date_u set "D"='1999-12-31' where "ID" = 1/);
} 'remote update date 1';

is_deeply(
  $dbh->selectall_arrayref(q/select "D" from test_xbase.date_u where "ID" = 1/, {Slice=>{}}),
  [{D=>'1999-12-31'}],
  'remote update date 1: updated'
);

lives_ok {
  $dbh->do(q/update test_xbase.date_u set "D"='2001-01-01' where "ID" = 1/);
} 'remote update date 2';

is_deeply (
  $dbh->selectall_arrayref(q/select "D" from test_xbase.date_u where "ID" = 1/, {Slice=>{}}),
  [{D=>'2001-01-01'}],
  'remote update date 2: updated'
);

