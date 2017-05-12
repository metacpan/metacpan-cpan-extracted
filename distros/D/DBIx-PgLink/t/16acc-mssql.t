use strict;

BEGIN {
  use Test::More;
  use Test::Exception;
  use Test::Deep;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_MSSQL}) {
    plan skip_all => 'TEST_MSSQL not configured';
  } else {
    plan tests => 15;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

sub get_row {
  $dbh->selectrow_hashref('SELECT * FROM northwind."Region" WHERE "RegionID"=?', {}, @_);
}

lives_ok {
  $dbh->do(q/delete from northwind."Region" where "RegionID"=100/);
} 'remote delete';

cmp_deeply(get_row(100), undef, 'remote select 1');

throws_ok {
  $dbh->do(q/insert into northwind."Region"("RegionID", "RegionDescription") select 1, 'foo'/);
} qr/Violation of PRIMARY KEY constraint/, 'remote insert (pk constraint violation)';

cmp_deeply(get_row(1), {RegionID=>1, RegionDescription=>re('Eastern +')}, 'remote select 2');

lives_ok {
  $dbh->do(q/insert into northwind."Region"("RegionID", "RegionDescription") select 100, 'underground'/);
} 'remote insert';

cmp_deeply(get_row(100), {RegionID=>100, RegionDescription=>re('underground +')}, 'remote select 3');

lives_ok {
  $dbh->do(q/update northwind."Region" set "RegionDescription"='stratosphere' where "RegionID"=100/);
} 'remote update';

cmp_deeply(get_row(100), {RegionID=>100, RegionDescription=>re('stratosphere +')}, 'remote select 4');

lives_ok {
  $dbh->do(q/delete from northwind."Region" where "RegionID"=100/);
} 'remote delete 2';

cmp_deeply(get_row(100), undef, 'remote select 5');


# one row, nested transaction

lives_ok {
  $dbh->do(q/select dbix_pglink.begin('TEST_MSSQL')/);
  eval {
    $dbh->do(q/insert into northwind."Region"("RegionID", "RegionDescription") select 100, 'underground'/);
    $dbh->do(q/delete from northwind."Region" where "RegionID"=100/);
    $dbh->do(q/select dbix_pglink.commit('TEST_MSSQL')/);
  };
  if ($@) {
    lives_ok {
      $dbh->do(q/select dbix_pglink.rollback('TEST_MSSQL')/);
    } 'outer rollback';
    die $@;
  }
} 'nested transaction (ok)';

throws_ok {
  $dbh->do(q/select dbix_pglink.begin('TEST_MSSQL')/);
  eval {
    $dbh->do(q/insert into northwind."Region"("RegionID", "RegionDescription") select 1, 'bar'/);
    die 'This INSERT must fails';
    $dbh->do(q/select dbix_pglink.commit('TEST_MSSQL')/);
  };
  if ($@) {
    my $err = $@;
    lives_ok {
      $dbh->do(q/select dbix_pglink.rollback('TEST_MSSQL')/);
    } 'outer rollback';
    die $err;
  }
} qr/Modification of remote TABLE .* failed/, 'nested transaction (error)';


# routines
cmp_deeply(
  $dbh->selectall_arrayref(q/select * from northwind."CustOrdersDetail"(10248) order by 1/),
  [
['Mozzarella di Giovanni',	'34.8000',	5,	0,	'174.0000' ],
['Queso Cabrales',	'14.0000',	12,	0,	'168.0000' ],
['Singaporean Hokkien Fried Mee',	'9.8000',	10,	0,	'98.0000' ],
  ],
  'procedure1'
);

cmp_deeply(
  $dbh->selectall_arrayref(q/select * from northwind.pglink_test1(1)/),
  [
[1,	re('Eastern +')],
[2,	re('Western +')],
[3,	re('Northern +')],
[4,	re('Southern +')],
  ],
  'procedure2'
);
