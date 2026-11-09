use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k150: Deploy->apply refuses, before its first statement, what the
# server would refuse half way through the diff because the rows already in
# the table have no value for it.
#
# WHY it exists: ADD COLUMN ... NOT NULL without a default fails on a table
# that holds rows, and SET NOT NULL fails over a NULL. A diff that carries
# other statements ahead of it dies after those ran, with an error that names
# neither the situation nor the way out. The refusal names table and column
# and changes nothing. An empty table, and a column without a NULL, pass.

my $n = 0;

# The schema class whose table t has id, a (nullable, new), v (nullable per
# v_null) and, when given, w. a is there afterwards only if a statement ran.
sub target {
  my (%o) = @_;
  my $result = 'T194::Result::R' . ++$n;
  eval qq{
    package $result;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    1;
  } or die $@;
  $result->table('t');
  $result->add_columns(
    id => { data_type => 'bigint', is_nullable => 0 },
    a  => { data_type => 'text', is_nullable => 1 },
    v  => { data_type => 'text', is_nullable => $o{v_null} ? 1 : 0 },
    ( $o{w} ? (w => $o{w}) : () ),
  );
  $result->set_primary_key('id');

  my $class = 'T194::Schema::S' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->pg_schemas('public');
  $class->register_class(T => $result);
  return $class;
}

# A private database whose table t has id and v, and the given rows.
sub prepared {
  my ($tag, $to, @rows) = @_;
  my @db  = PrivatePgDatabase->create($tag);
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
  $dbh->do('CREATE TABLE t (id bigint PRIMARY KEY, v text)');
  $dbh->do('INSERT INTO t VALUES (?, ?)', undef, @$_) for @rows;
  $dbh->disconnect;
  my $schema = $to->connect(@db, { PrintError => 0, PrintWarn => 0 });
  my $diff = $schema->pg_deploy->diff;
  return ($schema, $diff);
}

sub columns_of {
  my ($schema) = @_;
  return join ',', @{ $schema->storage->dbh->selectcol_arrayref(
    q{SELECT attname FROM pg_attribute WHERE attrelid = 't'::regclass
      AND attnum > 0 AND NOT attisdropped ORDER BY attnum}) };
}

# --- add NOT NULL without a default, table holds rows -> refused ----------
{
  my ($schema, $diff) = prepared('t194a1',
    target(v_null => 1, w => { data_type => 'text' }), [ 1, 'x' ]);
  ok($diff->has_changes, 'add: the diff has the columns');
  ok(!eval { $schema->pg_deploy->apply($diff); 1 }, 'add on a table with rows: apply dies');
  like($@, qr/PostgreSQL refuses to add the column/, 'add: the text says refuses');
  like($@, qr/public\.t\.w/, 'add: it names schema, table and column');
  like($@, qr/NOT NULL without a default/, 'add: and the reason');
  is(columns_of($schema), 'id,v', 'add: no statement ran (not even the nullable a)');
  $schema->storage->disconnect;
}

# --- same, table empty -> goes through ------------------------------------
{
  my ($schema, $diff) = prepared('t194a2',
    target(v_null => 1, w => { data_type => 'text' }));
  ok(eval { $schema->pg_deploy->apply($diff); 1 }, 'add on an empty table: apply runs') or diag $@;
  is(columns_of($schema), 'id,v,a,w', 'add on an empty table: the columns are there');
  $schema->storage->disconnect;
}

# --- serial has a default: not refused over rows --------------------------
{
  my ($schema, $diff) = prepared('t194a3',
    target(v_null => 1, w => { data_type => 'serial' }), [ 1, 'x' ]);
  ok(eval { $schema->pg_deploy->apply($diff); 1 }, 'serial on a table with rows: apply runs') or diag $@;
  $schema->storage->disconnect;
}

# --- NOT NULL over NULLs -> refused ---------------------------------------
{
  my ($schema, $diff) = prepared('t194n1', target(v_null => 0), [ 1, undef ], [ 2, 'x' ]);
  ok(!eval { $schema->pg_deploy->apply($diff); 1 }, 'NOT NULL over a NULL: apply dies');
  like($@, qr/PostgreSQL refuses to make the column/, 'NOT NULL: the text says refuses');
  like($@, qr/public\.t\.v/, 'NOT NULL: it names schema, table and column');
  like($@, qr/holds rows where it is NULL/, 'NOT NULL: and the reason');
  is(columns_of($schema), 'id,v', 'NOT NULL: no statement ran (a was not added)');
  $schema->storage->disconnect;
}

# --- NOT NULL without NULLs -> goes through -------------------------------
{
  my ($schema, $diff) = prepared('t194n2', target(v_null => 0), [ 1, 'y' ], [ 2, 'x' ]);
  ok(eval { $schema->pg_deploy->apply($diff); 1 }, 'NOT NULL without a NULL: apply runs') or diag $@;
  is($schema->storage->dbh->selectrow_array(
    q{SELECT attnotnull FROM pg_attribute WHERE attrelid = 't'::regclass AND attname = 'v'}),
    1, 'NOT NULL: the column is NOT NULL');
  $schema->storage->disconnect;
}

done_testing;
