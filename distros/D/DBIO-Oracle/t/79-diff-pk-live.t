use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Oracle::Introspect;
use DBIO::Oracle::Diff::Table;

# LIVE (karr k60). The primary key of a live introspected model reaches the
# CREATE TABLE of the diff.
#
# Diff::Table writes PRIMARY KEY (...) from is_pk on the columns it is given.
# The tests that pinned that (t/50-diff.t) build their models by hand, with
# is_pk; the introspection did not set it, so for a model read from a server
# the key was never written. What this file claims:
#
#   1. A live introspected model marks the columns of a primary key with
#      is_pk and pk_position (1-based, in the order of the CONSTRAINT, not of
#      the table), and no other column.
#   2. Diff::Table, given the columns of that model as target_columns, writes
#      PRIMARY KEY (...) in the order of the constraint, and Oracle accepts
#      the statement: the table made from it has the same primary key.
#
# The whole of DBIO::Oracle::Diff creates a table with its columns and its
# keys (karr k37): t/81-diff-new-table.t and t/55-diff-index-live.t.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;

my $dbh = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});

sub wipe {
  for my $t (qw(T79_LIVE_ONE T79_LIVE_MULTI T79_LIVE_COPY)) {
    eval { $dbh->do("DROP TABLE $t CASCADE CONSTRAINTS PURGE"); 1 }
      or $@ =~ /ORA-00942\b/
      or die $@;
  }
}

wipe();

# The key of MULTI is (B, A, C): neither the order of the table nor the
# alphabet's. C is not part of it.
$dbh->do($_) for (
  'CREATE TABLE T79_LIVE_ONE (ID NUMBER(10) NOT NULL, NAME VARCHAR2(20),'
. ' CONSTRAINT T79_LIVE_ONE_PK PRIMARY KEY (ID))',
  'CREATE TABLE T79_LIVE_MULTI (A NUMBER(5) NOT NULL, X VARCHAR2(5),'
. ' B NUMBER(5) NOT NULL, C NUMBER(5) NOT NULL,'
. ' CONSTRAINT T79_LIVE_MULTI_PK PRIMARY KEY (B, A, C))',
);

my $model = DBIO::Oracle::Introspect->new(dbh => $dbh)->model;

sub marks {
  my ($table) = @_;
  return { map { $_->{column_name} => $_->{pk_position} }
           grep { $_->{is_pk} } @{ $model->{columns}{$table} } };
}

is_deeply marks('T79_LIVE_ONE'), { ID => 1 },
  'the single-column key is marked is_pk with position 1';

is_deeply marks('T79_LIVE_MULTI'), { B => 1, A => 2, C => 3 },
  'the key of three columns is marked in the order of the constraint, '
. 'not of the table';

is_deeply [ grep { !$_->{is_pk} && exists $_->{pk_position} }
            map { @{ $model->{columns}{$_} } } qw(T79_LIVE_ONE T79_LIVE_MULTI) ],
  [], 'a column outside the key carries no pk_position';

is_deeply $model->{primary_keys}{T79_LIVE_MULTI}, [qw(B A C)],
  'the primary_keys section stays, in the same order';

# ---- the CREATE TABLE

for my $name (qw(T79_LIVE_ONE T79_LIVE_MULTI)) {
  my ($op) = DBIO::Oracle::Diff::Table->diff(
    {},
    { $name => $model->{tables}{$name} },
    { $name => $model->{columns}{$name} },
    { $name => [] },
  );
  my $sql = $op->as_sql;

  my $expect = join ', ', map { qq{"$_"} } @{ $model->{primary_keys}{$name} };
  like $sql, qr/PRIMARY KEY \(\Q$expect\E\)/,
    "$name: the CREATE TABLE from the introspected columns has PRIMARY KEY ($expect)";
}

{
  # Run the statement for MULTI under another name and look at the key the
  # server then holds.
  my ($op) = DBIO::Oracle::Diff::Table->diff(
    {},
    { T79_LIVE_COPY => { table_name => 'T79_LIVE_COPY' } },
    { T79_LIVE_COPY => $model->{columns}{T79_LIVE_MULTI} },
    {},
  );
  (my $sql = $op->as_sql) =~ s/;\s*\z//;
  $dbh->do($sql);

  my $keys = $dbh->selectcol_arrayref(q{
    SELECT cc.column_name FROM user_constraints c
    JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
    WHERE c.table_name = 'T79_LIVE_COPY' AND c.constraint_type = 'P'
    ORDER BY cc.position
  });
  is_deeply $keys, [qw(B A C)],
    'Oracle accepts the statement, and the table made from it has the primary '
  . 'key of the model, in the order of the constraint';
}

END { wipe() if $dbh }

done_testing;
