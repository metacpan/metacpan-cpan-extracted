use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Introspect;

# Live round-trip for the declared indexes (karr k88, ADR 0061 in core): a
# database installed without them is upgraded to a schema whose result class
# declares a plain, a unique and a two-column index through DBIO::Cake idx.
# The diff must carry the three CREATE INDEX (the desired model is the temp
# database the DDL was deployed into), apply cleanly, Introspect must read
# them back with their columns and uniqueness, and a second diff is empty.
#
# Runs in a throwaway database it creates and drops itself; needs a login
# allowed to CREATE DATABASE (sa on the docker/k8s ASE image).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

{
  package DBIO::Sybase::Test::K88::V1::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k88_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    sku  => { data_type => 'varchar', size => 20 },
    name => { data_type => 'varchar', size => 50 },
    city => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Sybase::Test::K88::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Item => 'DBIO::Sybase::Test::K88::V1::Item');

  package DBIO::Sybase::Test::K88::V2::Item;
  use DBIO::Cake;
  table 'k88_item';
  col id   => integer auto_inc;
  col sku  => varchar(20);
  col name => varchar(50);
  col city => varchar(50);
  primary_key 'id';
  idx k88_name_idx     => ['name'];
  idx k88_sku_uq       => ['sku'], type => 'unique';
  idx k88_name_city_ix => ['name', 'city'];

  package DBIO::Sybase::Test::K88::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Item => 'DBIO::Sybase::Test::K88::V2::Item');
}

my $db = "dbio_k88_idx_$$";
my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ($dsn =~ /:$/ ? '' : ';') . "database=$db";

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('USE master');
$admin->do("CREATE DATABASE $db");

my $ok = eval {
  my $v1 = DBIO::Sybase::Test::K88::V1->connect($db_dsn, $user, $pass);
  DBIO::Sybase::Deploy->new(schema => $v1)->install;
  $v1->storage->disconnect;

  my $v2 = DBIO::Sybase::Test::K88::V2->connect($db_dsn, $user, $pass);
  my $deploy = DBIO::Sybase::Deploy->new(schema => $v2);

  my $diff = $deploy->diff;
  my $sql = $diff->as_sql;
  like $sql, qr/CREATE INDEX k88_name_idx ON k88_item \(name\)/, 'diff: plain index';
  like $sql, qr/CREATE UNIQUE INDEX k88_sku_uq ON k88_item \(sku\)/, 'diff: unique index';
  like $sql, qr/CREATE INDEX k88_name_city_ix ON k88_item \(name, city\)/,
    'diff: two-column index';

  $deploy->apply($diff);

  my $intro = DBIO::Sybase::Introspect->new(dbh => $v2->storage->dbh);
  my $idx = $intro->model->{indexes}{k88_item};
  is_deeply $idx->{k88_name_idx}{columns}, ['name'], 'introspect: plain index columns';
  ok !$idx->{k88_name_idx}{is_unique}, 'introspect: plain index is not unique';
  ok $idx->{k88_sku_uq}{is_unique}, 'introspect: unique index is unique';
  is_deeply $idx->{k88_name_city_ix}{columns}, [qw/name city/],
    'introspect: two-column index, key order';

  my $again = $deploy->diff;
  ok !$again->has_changes, 'a second diff is empty' or diag $again->as_sql;

  $v2->storage->disconnect;
  1;
};
my $err = $@;

eval { $admin->do('USE master') };
is AseDatabase::drop($admin, $db), '', "the database of this test, $db, is dropped";

die $err unless $ok;

done_testing;
