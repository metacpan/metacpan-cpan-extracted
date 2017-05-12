use strict;

BEGIN {
  use Test::More;
  use Test::Exception;
  use Test::Deep;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_SYBASE}) {
    plan skip_all => 'TEST_SYBASE not configured';
  } else {
    plan tests => 2;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

#sub get_row {
#  $dbh->selectrow_hashref('SELECT * FROM test_sybase."Region" WHERE "RegionID"=?', {}, @_);
#}
#
#lives_ok {
#  $dbh->do(q/delete from test_sybase."Region" where "RegionID"=100/);
#} 'remote delete';
#
#cmp_deeply(get_row(100), undef, 'remote select 1');
#
#throws_ok {
#  $dbh->do(q/insert into test_sybase."Region"("RegionID", "RegionDescription") select 1, 'foo'/);
#} qr/Violation of PRIMARY KEY constraint/, 'remote insert (pk constraint violation)';
#
#cmp_deeply(get_row(1), {RegionID=>1, RegionDescription=>re('Eastern +')}, 'remote select 2');
#
#lives_ok {
#  $dbh->do(q/insert into test_sybase."Region"("RegionID", "RegionDescription") select 100, 'underground'/);
#} 'remote insert';
#
#cmp_deeply(get_row(100), {RegionID=>100, RegionDescription=>re('underground +')}, 'remote select 3');
#
#lives_ok {
#  $dbh->do(q/update test_sybase."Region" set "RegionDescription"='stratosphere' where "RegionID"=100/);
#} 'remote update';
#
#cmp_deeply(get_row(100), {RegionID=>100, RegionDescription=>re('stratosphere +')}, 'remote select 4');
#
#lives_ok {
#  $dbh->do(q/delete from test_sybase."Region" where "RegionID"=100/);
#} 'remote delete 2';
#
#cmp_deeply(get_row(100), undef, 'remote select 5');
#
#
## one row, nested transaction
#
#lives_ok {
#  $dbh->do(q/select dbix_pglink.begin('TEST_SYBASE')/);
#  eval {
#    $dbh->do(q/insert into test_sybase."Region"("RegionID", "RegionDescription") select 100, 'underground'/);
#    $dbh->do(q/delete from test_sybase."Region" where "RegionID"=100/);
#    $dbh->do(q/select dbix_pglink.commit('TEST_SYBASE')/);
#  };
#  if ($@) {
#    lives_ok {
#      $dbh->do(q/select dbix_pglink.rollback('TEST_SYBASE')/);
#    } 'outer rollback';
#    die $@;
#  }
#} 'nested transaction (ok)';
#
#throws_ok {
#  $dbh->do(q/select dbix_pglink.begin('TEST_SYBASE')/);
#  eval {
#    $dbh->do(q/insert into test_sybase."Region"("RegionID", "RegionDescription") select 1, 'bar'/);
#    die 'This INSERT must fails';
#    $dbh->do(q/select dbix_pglink.commit('TEST_SYBASE')/);
#  };
#  if ($@) {
#    my $err = $@;
#    lives_ok {
#      $dbh->do(q/select dbix_pglink.rollback('TEST_SYBASE')/);
#    } 'outer rollback';
#    die $err;
#  }
#} qr/Modification of remote TABLE .* failed/, 'nested transaction (error)';


# routines
cmp_deeply(
  $dbh->selectall_arrayref(q/select * from test_sybase.byroyalty(25) order by 1/),
  [
    ['724-80-9391'],
    ['899-46-2035'],
  ],
  'procedure1'
);

cmp_deeply(
  $dbh->selectall_arrayref(q/select * from test_sybase.pglink_test1(1)/),
  [
['Customer Discount',	5.0],
['Huge Volume Discount',	10.0],
['Initial Customer', 10.5],
['Volume Discount',	6.7],
  ],
  'procedure2'
);
