use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_FIREBIRD_DSN};

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Test::Conformance;

# LIVE (karr k55): the cleanup of the conformance class touches the objects of
# its own run and nothing else.
#
# WHY: the core runner calls conformance_cleanup after EVERY case, also when
# conformance_namespace threw. The namespace seam throws exactly when the
# database holds somebody else's table or view; a cleanup that then dropped
# "everything in the database" destroyed what the namespace check had just
# refused to use. The mark conformance_namespace returns (the tables and views
# the case will create) is the whole of what the cleanup may remove.
#
# Each test calls the seams in the runner's order: connect, namespace in an
# eval, cleanup with whatever the namespace gave (undef when it threw).
#
# WARNING: creates and drops "dbio_t85_foreign", "dbio_t85_fview",
# "dbio_t85_mine_a", "dbio_t85_mine_b", "dbio_t85_mine_v". The database must
# otherwise be empty, as for t/80 (which this file must not run beside).

my $class = 'DBIO::Firebird::Test::Conformance';
my ($case) = grep { $_->{name} eq 'ddl-foreign-key' } @{ $class->cases('DDL') };
die "the case table has no ddl-foreign-key" unless $case;

sub own_dbh {
  return DBI->connect(@ENV{qw(DBIO_TEST_FIREBIRD_DSN DBIO_TEST_FIREBIRD_USER DBIO_TEST_FIREBIRD_PASS)},
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1, ib_dialect => 3 });
}

sub relations {
  my ($dbh) = @_;
  my $rows = $dbh->selectall_arrayref(
    'SELECT rdb$relation_name FROM rdb$relations WHERE COALESCE(rdb$system_flag, 0) = 0');
  return { map { my $n = $_->[0]; $n =~ s/\s+\z//; ($n => 1) } @$rows };
}

my @all = qw(dbio_t85_foreign dbio_t85_fview dbio_t85_mine_a dbio_t85_mine_b dbio_t85_mine_v);

my $dbh = own_dbh();
my $wipe = sub {
  for my $stmt (
    'ALTER TABLE "dbio_t85_mine_b" DROP CONSTRAINT "dbio_t85_mine_fk"',
    (map { qq{DROP VIEW "$_"} } qw(dbio_t85_fview dbio_t85_mine_v)),
    (map { qq{DROP TABLE "$_"} } qw(dbio_t85_foreign dbio_t85_mine_b dbio_t85_mine_a)),
  ) { eval { $dbh->do($stmt) } }
};
$wipe->();
{
  my $left = relations($dbh);
  my @there = sort keys %$left;
  plan skip_all => "the database is not empty (@there): not this test's to use"
    if @there;
}

# somebody else's table and view
$dbh->do('CREATE TABLE "dbio_t85_foreign" ("id" INTEGER NOT NULL PRIMARY KEY)');
$dbh->do('CREATE VIEW "dbio_t85_fview" AS SELECT "id" FROM "dbio_t85_foreign"');

my $survives = sub {
  my ($label) = @_;
  my $r = relations($dbh);
  ok $r->{dbio_t85_foreign}, "$label: the foreign table is still there";
  ok $r->{dbio_t85_fview},   "$label: the foreign view is still there";
};

# 1. the runner's order, the namespace seam refuses
{
  my $schema_class = $class->_build_schema_class($case);
  my $schema = $class->conformance_connect($schema_class);
  my $namespace;
  my $ran = eval { $namespace = $class->conformance_namespace($schema, $case); 1 };
  ok !$ran, 'namespace refuses a database that holds a foreign table and view';
  like "$@", qr/dbio_t85_foreign/, '... and names what is there';
  ok !defined $namespace, '... there is no mark';
  ok eval { $class->conformance_cleanup($schema, $case, $namespace); 1 },
    'cleanup after the refused namespace does not die' or diag $@;
  $survives->('after the refused namespace');
}

# 2. a mark of other names touches nothing foreign
{
  my $schema = $class->conformance_connect($class->_build_schema_class($case));
  ok eval { $class->conformance_cleanup($schema, $case,
      { tables => [ qw(parent child) ], views => [ 'some_view' ] }); 1 },
    'cleanup with a mark of other names does not die' or diag $@;
  $survives->('after a mark of other names');
}

# 3. a mark removes its own objects (keys, view, tables) and only those
{
  $dbh->do('CREATE TABLE "dbio_t85_mine_a" ("id" INTEGER NOT NULL PRIMARY KEY)');
  $dbh->do('CREATE TABLE "dbio_t85_mine_b" ("id" INTEGER NOT NULL PRIMARY KEY, "a" INTEGER)');
  $dbh->do('ALTER TABLE "dbio_t85_mine_b" ADD CONSTRAINT "dbio_t85_mine_fk" '
         . 'FOREIGN KEY ("a") REFERENCES "dbio_t85_mine_a" ("id")');
  $dbh->do('CREATE VIEW "dbio_t85_mine_v" AS SELECT "id" FROM "dbio_t85_mine_a"');

  my $schema = $class->conformance_connect($class->_build_schema_class($case));
  my $mark = { tables => [ qw(dbio_t85_mine_a dbio_t85_mine_b) ], views => [ 'dbio_t85_mine_v' ] };
  ok eval { $class->conformance_cleanup($schema, $case, $mark); 1 },
    'cleanup with its own mark (key, view, two tables)' or diag $@;
  my $r = relations($dbh);
  ok !$r->{$_}, "$_ is gone" for qw(dbio_t85_mine_a dbio_t85_mine_b dbio_t85_mine_v);
  $survives->('after its own mark');
}

# 4. the mark itself: what the namespace seam returns on an empty database
{
  $dbh->do('DROP VIEW "dbio_t85_fview"');
  $dbh->do('DROP TABLE "dbio_t85_foreign"');
  my $schema = $class->conformance_connect($class->_build_schema_class($case));
  my $mark = eval { $class->conformance_namespace($schema, $case) };
  is_deeply $mark, { tables => [ qw(child parent) ], views => [] },
    'on an empty database the namespace returns the tables the case will create'
    or diag $@;
  $class->conformance_cleanup($schema, $case, $mark);
}

$wipe->();
$dbh->disconnect;
done_testing;
