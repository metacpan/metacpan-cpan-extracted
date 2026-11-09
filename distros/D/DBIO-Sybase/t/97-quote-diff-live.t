use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Introspect;

# LIVE (karr k92). Names that are ASE keywords, through the whole cycle the
# driver has: install, introspect, diff, apply. Table `dummy` (the one of
# DBIO::Test::Schema::Dummy), `order`, `view`; columns `key`, `user`, `group`,
# `index`; a unique index `check`, an index `select`.
#
#   1. The schema installs (it was Msg 156 at the first CREATE TABLE).
#   2. The catalog holds the names without brackets, and the diff of the
#      schema against its own deployment is empty.
#   3. The second version -- a column widened, a default replaced, a column
#      added and one dropped, an index changed and one dropped, a table and a
#      foreign key added -- is a diff whose every statement names the keywords
#      in brackets, applies, and leaves a second diff empty.
#
# Runs in a throwaway database it creates and drops itself; needs a login
# allowed to CREATE DATABASE.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && defined $user && defined $pass;

{
  package K92::V1::Dummy;
  use base 'DBIO::Core';
  __PACKAGE__->table('dummy');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    key  => { data_type => 'varchar', size => 20 },
    user => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => 'a' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(check => ['key']);
  __PACKAGE__->indices(select => ['user']);

  package K92::V1::Order;
  use base 'DBIO::Core';
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    dummy_id => { data_type => 'integer' },
    index    => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(dummy => 'K92::V1::Dummy', 'dummy_id');

  package K92::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Dummy => 'K92::V1::Dummy');
  __PACKAGE__->register_class(Order => 'K92::V1::Order');

  package K92::V2::Dummy;
  use base 'DBIO::Core';
  __PACKAGE__->table('dummy');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    key   => { data_type => 'varchar', size => 40 },
    user  => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => 'b' },
    group => { data_type => 'integer', default_value => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(check => ['key']);
  __PACKAGE__->indices(select => ['user', 'group']);

  package K92::V2::Order;
  use base 'DBIO::Core';
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    dummy_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(dummy => 'K92::V2::Dummy', 'dummy_id');

  package K92::V2::View;
  use base 'DBIO::Core';
  __PACKAGE__->table('view');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    dummy_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(dummy => 'K92::V2::Dummy', 'dummy_id');

  package K92::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Dummy => 'K92::V2::Dummy');
  __PACKAGE__->register_class(Order => 'K92::V2::Order');
  __PACKAGE__->register_class(View  => 'K92::V2::View');
}

my $db = "dbio_k92_rt_$$";
my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ($dsn =~ /:$/ ? '' : ';') . "database=$db";

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('USE master');
$admin->do("CREATE DATABASE $db");
{
  local $admin->{syb_err_handler} = sub { $_[1] > 10 ? 1 : 0 };
  # abort tran on log full: a full log is refused, not waited on (karr k69);
  # select into/bulkcopy: the data-copying ALTER TABLE of the modify and drop.
  for my $option ('abort tran on log full', 'select into/bulkcopy/pllsort') {
    my $sth = $admin->prepare("exec sp_dboption '$db', '$option', true");
    $sth->execute;
    do { 1 while $sth->fetchrow_arrayref } while $sth->{syb_more_results};
  }
}

my $ok = eval {
  my $v1 = K92::V1->connect($db_dsn, $user, $pass);
  ok eval { DBIO::Sybase::Deploy->new(schema => $v1)->install; 1 },
    'a schema with the tables dummy and order installs' or diag $@;

  my $model = DBIO::Sybase::Introspect->new(dbh => $v1->storage->dbh)->model;
  is_deeply [ sort keys %{ $model->{tables} } ], [qw(dummy order)],
    'the catalog holds the table names without brackets';
  is_deeply [ map { $_->{column_name} } @{ $model->{columns}{dummy} } ], [qw(id key user)],
    '... and the column names';
  is_deeply [ sort map { $_->{index_name} } grep { ($_->{origin} // '') ne 'pk' } values %{ $model->{indexes}{dummy} } ],
    [qw(check select)],
    '... and the names of the indexes';

  my $same = DBIO::Sybase::Deploy->new(schema => $v1)->diff;
  ok !$same->has_changes, 'the diff of the schema against its own deployment is empty'
    or diag $same->as_sql;
  $v1->storage->disconnect;

  my $v2 = K92::V2->connect($db_dsn, $user, $pass);
  my $deploy = DBIO::Sybase::Deploy->new(schema => $v2);
  my $diff = $deploy->diff;
  my $sql  = $diff->as_sql;
  diag $sql if $ENV{TEST_VERBOSE};

  like $sql, qr/^CREATE TABLE \[view\] \(/m,                       'the diff creates the table view, bracketed';
  like $sql, qr/^ALTER TABLE \[dummy\] ADD \[group\] INT DEFAULT 0 NOT NULL;/m, '... adds the column group';
  like $sql, qr/^ALTER TABLE \[dummy\] MODIFY \[key\] VARCHAR\(40\)/m, '... widens key';
  like $sql, qr/^ALTER TABLE \[dummy\] REPLACE \[user\] DEFAULT 'b';/m, '... replaces the default of user';
  like $sql, qr/^ALTER TABLE \[order\] DROP \[index\];/m,           '... drops the column index';
  like $sql, qr/DROP INDEX \[dummy\]\.\[select\]; CREATE INDEX \[select\] ON \[dummy\] \(\[user\], \[group\]\);/,
    '... changes the index select';
  like $sql, qr/^ALTER TABLE \[view\] ADD CONSTRAINT \S+ FOREIGN KEY \(dummy_id\) REFERENCES \[dummy\] \(id\);/m,
    '... adds the foreign key from view to dummy';
  unlike $sql, qr/"/, '... and writes no double quote';

  ok eval { $deploy->apply($diff, allow_destructive => 1); 1 }, 'the diff applies (it drops the column index, ADR 0080)' or diag $@;

  my $m2 = DBIO::Sybase::Introspect->new(dbh => $v2->storage->dbh)->model;
  is_deeply [ sort keys %{ $m2->{tables} } ], [qw(dummy order view)], 'the catalog now holds dummy, order and view';

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
