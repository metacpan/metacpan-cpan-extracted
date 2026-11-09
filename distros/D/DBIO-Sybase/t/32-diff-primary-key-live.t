use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Introspect;

# Live round-trip for the primary key in the diff (karr k53): a database
# installed with PK(a) is upgraded to a schema whose key is (a, b) and which
# adds a table of its own; the diff must carry the key change, apply cleanly,
# and a second diff must be empty. Before k53 the first diff was empty for the
# key (Diff::Index leaves the PK index out, nothing else compared it) and the
# new table was created without its key.
#
# Runs in a throwaway database it creates and drops itself; needs a login
# allowed to CREATE DATABASE (sa on the docker/k8s ASE image).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

# Two versions of one small schema; the shapes are the point of the test, so
# they are spelled out here rather than taken from DBIO::Test::Schema.
{
  package DBIO::Sybase::Test::K53::V1::Pair;
  use base 'DBIO::Core';
  __PACKAGE__->table('k53_pair');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer' },
    b => { data_type => 'integer', default_value => 0 },
  );
  __PACKAGE__->set_primary_key('a');

  package DBIO::Sybase::Test::K53::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Pair => 'DBIO::Sybase::Test::K53::V1::Pair');

  package DBIO::Sybase::Test::K53::V2::Pair;
  use base 'DBIO::Core';
  __PACKAGE__->table('k53_pair');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer' },
    b => { data_type => 'integer', default_value => 0 },
  );
  __PACKAGE__->set_primary_key(qw/a b/);

  package DBIO::Sybase::Test::K53::V2::Fresh;
  use base 'DBIO::Core';
  __PACKAGE__->table('k53_fresh');
  __PACKAGE__->add_columns(
    x => { data_type => 'integer' },
    y => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key(qw/y x/);

  package DBIO::Sybase::Test::K53::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Pair  => 'DBIO::Sybase::Test::K53::V2::Pair');
  __PACKAGE__->register_class(Fresh => 'DBIO::Sybase::Test::K53::V2::Fresh');
}

my $db = "dbio_k53_rt_$$";
my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ($dsn =~ /:$/ ? '' : ';') . "database=$db";

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('USE master');
$admin->do("CREATE DATABASE $db");

my $ok = eval {
  my $v1 = DBIO::Sybase::Test::K53::V1->connect($db_dsn, $user, $pass);
  DBIO::Sybase::Deploy->new(schema => $v1)->install;
  $v1->storage->dbh->do('INSERT INTO k53_pair (a, b) VALUES (1, 1)');
  $v1->storage->disconnect;

  my $v2 = DBIO::Sybase::Test::K53::V2->connect($db_dsn, $user, $pass);
  my $deploy = DBIO::Sybase::Deploy->new(schema => $v2);

  my $diff = $deploy->diff;
  my @sql = map { $_->as_sql } @{ $diff->operations };
  like $sql[0], qr/\ACREATE TABLE k53_fresh \(.*PRIMARY KEY \(y, x\)\n\);\z/s,
    'the new table is created with its key, in key order';
  like $sql[1], qr/\AALTER TABLE k53_pair DROP CONSTRAINT k53_pair_\d+;\z/,
    'the live key is dropped by its server-assigned name';
  is $sql[2], 'ALTER TABLE k53_pair ADD PRIMARY KEY (a, b);', '... and the new key added';
  is scalar(@sql), 3, 'nothing else';

  $deploy->apply($diff, allow_destructive => 1);   # the old key is dropped (ADR 0080)

  my $intro = DBIO::Sybase::Introspect->new(dbh => $v2->storage->dbh);
  is_deeply $intro->table_pk_info('k53_pair'),  [qw/a b/], 'k53_pair key is (a, b) after apply';
  is_deeply $intro->table_pk_info('k53_fresh'), [qw/y x/], 'k53_fresh key is (y, x)';
  is scalar $v2->storage->dbh->selectrow_array('SELECT COUNT(*) FROM k53_pair'), 1,
    'the row survived the key change';

  my $again = $deploy->diff;
  ok !$again->has_changes, 'a second diff is empty' or diag $again->as_sql;

  $v2->storage->disconnect;
  1;
};
my $err = $@;

# The server may refuse the drop for a moment (Msg 3702, karr k74): repeated
# in t/lib/AseDatabase.pm, and a database that stays is a failure by name.
eval { $admin->do('USE master') };
is AseDatabase::drop($admin, $db), '', "the database of this test, $db, is dropped";

die $err unless $ok;

done_testing;
