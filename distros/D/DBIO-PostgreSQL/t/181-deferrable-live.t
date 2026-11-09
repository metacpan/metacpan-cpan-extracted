use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k147: DEFERRABLE / INITIALLY DEFERRED of a FOREIGN KEY and
# a UNIQUE constraint are in the model (deferrable, initially_deferred),
# written by the install and the diff, and compared.
#
# WHY it exists: the model read condeferrable for a foreign key and nothing for
# a UNIQUE constraint; install and diff wrote it nowhere, so a deferrable key
# lost it where the diff had to create it, and a change was "no changes".
#
# Claims, each against a server:
#
#  1. an install of a deferrable foreign key and UNIQUE constraint makes them
#     so in the catalog, the introspection reads both keys back, and the
#     second diff is empty;
#  2. a table the diff creates gets the same constraints as the install;
#  3. a change of the timing (either key, either way, immediate <-> deferred)
#     is a drop and a create, the catalog follows, the second diff is empty;
#  4. a unique index no constraint stands on becomes the DEFERRABLE
#     constraint with ADD CONSTRAINT ... USING INDEX, no second index;
#  5. what DEFERRED is for: a deferred key lets a row in ahead of its parent
#     inside the transaction.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $serial = 0;

# The name of the UNIQUE constraint of the schema classes (a rename case sets another).
our $UNAME = 'child_code_key';

# parent + child, the belongs_to with %$fk attributes, the UNIQUE constraint
# $UNAME with the pg_unique_options %$unique.
sub schema_class {
  my ($fk, $unique) = @_;
  my $name = 'T181::S' . ++$serial;
  no strict 'refs';
  for my $table (qw( parent child )) {
    my $result = "${name}::Result::" . ucfirst $table;
    @{"${result}::ISA"} = ('DBIO::Core');
    $result->load_components('PostgreSQL::Result');
    $result->table($table);
    $result->add_columns(
      id => { data_type => 'bigint', is_nullable => 0 },
      ($table eq 'child' ? (
        parent_id => { data_type => 'bigint', is_nullable => 0 },
        code      => { data_type => 'text',   is_nullable => 0 },
      ) : ()),
    );
    $result->set_primary_key('id');
  }
  my $child = "${name}::Result::Child";
  $child->belongs_to(parent => "${name}::Result::Parent", 'parent_id', {%$fk});
  $child->pg_fk_constraints_from_rels(1);
  $child->add_unique_constraint($UNAME => ['code']);
  $child->pg_unique_options($UNAME => $unique) if $unique && %$unique;
  @{"${name}::ISA"} = ('DBIO::Schema');
  $name->load_components('PostgreSQL');
  $name->register_class($_ => "${name}::Result::$_") for qw( Parent Child );
  return $name;
}

sub stock {
  my ($tag, $fk, $unique, @stock) = @_;
  my $schema = schema_class($fk, $unique)->connect(PrivatePgDatabase->create($tag), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for @stock;
  return ($schema, $dbh);
}

sub statements { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

# The constraints of child, as "name type deferrable deferred".
sub timing {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT conname || ' ' || contype::text || ' ' || condeferrable::text || ' ' || condeferred::text
    FROM pg_catalog.pg_constraint
    WHERE conrelid = 'child'::pg_catalog.regclass AND contype IN ('f', 'u') ORDER BY 1});
}

sub settled {
  my ($label, $schema) = @_;
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, "$label: the diff after it is built") or diag $@;
  ok($diff && !$diff->has_changes, "$label: ... and finds nothing left to do") or diag $diff && $diff->as_sql;
}

my $IMMEDIATE = { deferrable => 1 };
my $DEFERRED  = { deferrable => 1, initially_deferred => 1 };

# ---------------------------------------------------------------------------
# 1. The install, the model, the second diff
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t181i', $DEFERRED, $IMMEDIATE);
  note 'server ' . $dbh->selectrow_array('SHOW server_version');
  $schema->pg_deploy->install;
  is_deeply(timing($dbh), [
      'child_code_key u true false',
      'child_parent_id_fkey f true true',
    ], 'the install makes the foreign key DEFERRED and the UNIQUE constraint IMMEDIATE (condeferrable, condeferred)');

  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  my ($fk) = grep { $_->{constraint_name} eq 'child_parent_id_fkey' } @{ $model->{foreign_keys}{'public.child'} };
  is_deeply([ @{$fk}{qw( deferrable initially_deferred is_deferrable )} ], [ 1, 1, 1 ],
    'the model holds the foreign key as deferrable and initially_deferred (is_deferrable stays)');
  my $u = $model->{indexes}{'public.child'}{child_code_key};
  is_deeply([ @{$u}{qw( constraint_type deferrable initially_deferred )} ], [ 'u', 1, 0 ],
    '... and the UNIQUE constraint as deferrable, not initially_deferred');
  my $pk = $model->{indexes}{'public.child'}{child_pkey};
  is_deeply([ @{$pk}{qw( deferrable initially_deferred )} ], [ 0, 0 ], '... a primary key as neither');

  settled('install', $schema);

  # 5. what it is for
  my $ok = eval {
    $dbh->begin_work;
    $dbh->do(q{INSERT INTO child VALUES (1, 100, 'x')});
    $dbh->do(q{INSERT INTO parent VALUES (100)});
    $dbh->commit;
    1;
  };
  ok($ok, 'a DEFERRED key lets the child in ahead of its parent inside the transaction') or do { diag $@; $dbh->rollback };
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 2. Tables the diff creates
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t181n', $DEFERRED, $IMMEDIATE);
  my $deploy = $schema->pg_deploy;
  my $diff = $deploy->diff;
  like(join("\n", @{ statements($diff) }),
    qr/FOREIGN KEY \(parent_id\) REFERENCES public\.parent \(id\) DEFERRABLE INITIALLY DEFERRED;$/m,
    'tables to create: the diff writes the foreign key DEFERRABLE INITIALLY DEFERRED');
  $deploy->apply($diff);
  is_deeply(timing($dbh), [
      'child_code_key u true false',
      'child_parent_id_fkey f true true',
    ], '... after apply the catalog reads like the one of the install');
  settled('tables to create', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 3. A change of the timing
# ---------------------------------------------------------------------------
{
  my @base = (
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL, code text NOT NULL,'
      . ' CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id)%s,'
      . ' CONSTRAINT child_code_key UNIQUE (code)%s)',
  );
  my $database = sub { my ($fk, $uq) = @_; return ($base[0], sprintf($base[1], $fk, $uq)) };

  for my $case (
    [ 'not deferrable to deferrable',   ['', ''],                                     [{}, {}],        [$IMMEDIATE, $IMMEDIATE], [ 'child_code_key u true false', 'child_parent_id_fkey f true false' ] ],
    [ 'immediate to deferred',          [' DEFERRABLE', ' DEFERRABLE'],               [$IMMEDIATE, $IMMEDIATE], [$DEFERRED, $DEFERRED],  [ 'child_code_key u true true', 'child_parent_id_fkey f true true' ] ],
    [ 'deferred to immediate',          [' DEFERRABLE INITIALLY DEFERRED', ' DEFERRABLE INITIALLY DEFERRED'], [$DEFERRED, $DEFERRED], [$IMMEDIATE, $IMMEDIATE], [ 'child_code_key u true false', 'child_parent_id_fkey f true false' ] ],
    [ 'deferrable to not deferrable',   [' DEFERRABLE', ' DEFERRABLE'],               [$IMMEDIATE, $IMMEDIATE], [{}, {}],              [ 'child_code_key u false false', 'child_parent_id_fkey f false false' ] ],
  ) {
    my ($label, $from, undef, $to, $want) = @$case;
    my ($schema, $dbh) = stock('t181c', $to->[0], $to->[1], $database->(@$from));
    my $deploy = $schema->pg_deploy;
    my $diff = $deploy->diff;
    my $sql = join "\n", @{ statements($diff) };
    like($sql, qr/DROP CONSTRAINT child_parent_id_fkey;.*ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY/s,
      "$label: the foreign key is dropped and created again") or diag $sql;
    like($sql, qr/DROP CONSTRAINT child_code_key;.*ADD CONSTRAINT child_code_key UNIQUE \(code\)/s,
      "$label: so is the UNIQUE constraint") or diag $sql;
    eval { $deploy->apply($diff) } or diag $@;
    is_deeply(timing($dbh), $want, "$label: the catalog follows");
    settled($label, $schema);
    $schema->storage->disconnect;
  }
}

# ---------------------------------------------------------------------------
# 4. The unique index becomes the DEFERRABLE constraint, USING INDEX
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t181u', $DEFERRED, $DEFERRED,
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL, code text NOT NULL,'
      . ' CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id) DEFERRABLE INITIALLY DEFERRED)',
    'CREATE UNIQUE INDEX child_code_key ON child (code)');
  my $deploy = $schema->pg_deploy;
  my $diff = $deploy->diff;
  my $sql = join "\n", @{ statements($diff) };
  like($sql, qr/ADD CONSTRAINT child_code_key UNIQUE USING INDEX child_code_key DEFERRABLE INITIALLY DEFERRED;/,
    'the unique index of the database takes the constraint with its timing') or diag $sql;
  eval { $deploy->apply($diff) } or diag $@;
  is_deeply(timing($dbh), [ 'child_code_key u true true', 'child_parent_id_fkey f true true' ], '... the catalog has it');
  is($dbh->selectrow_array(q{SELECT count(*) FROM pg_catalog.pg_indexes WHERE tablename = 'child' AND indexname LIKE 'child_code%'}),
    1, '... on the index it had, no second one');
  settled('using index', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 5. A UNIQUE constraint under another name: a rename keeps the timing, a
#    rename that changes it is a drop and a create
# ---------------------------------------------------------------------------
{
  my $database = sub {
    my ($uq) = @_;
    return (
      'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
      'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL, code text NOT NULL,'
        . ' CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id) DEFERRABLE INITIALLY DEFERRED,'
        . " CONSTRAINT child_old_key UNIQUE (code)$uq)",
    );
  };

  {
    my ($schema, $dbh) = stock('t181r', $DEFERRED, $IMMEDIATE, $database->(' DEFERRABLE'));
    my $deploy = $schema->pg_deploy;
    my $diff = $deploy->diff;
    my $sql = join "\n", @{ statements($diff) };
    like($sql, qr/ALTER TABLE public\.child RENAME CONSTRAINT child_old_key TO child_code_key;/, 'a rename with the same timing is a RENAME CONSTRAINT') or diag $sql;
    unlike($sql, qr/DROP CONSTRAINT/, '... and drops nothing');
    eval { $deploy->apply($diff) } or diag $@;
    is_deeply(timing($dbh), [ 'child_code_key u true false', 'child_parent_id_fkey f true true' ], '... the catalog follows, the timing kept');
    settled('rename', $schema);
    $schema->storage->disconnect;
  }

  for my $case (
    [ 'rename and NOT DEFERRABLE to DEFERRABLE', '',            $IMMEDIATE, 'child_code_key u true false' ],
    [ 'rename and DEFERRABLE to NOT DEFERRABLE', ' DEFERRABLE', {},         'child_code_key u false false' ],
    [ 'rename and IMMEDIATE to DEFERRED',        ' DEFERRABLE', $DEFERRED,  'child_code_key u true true' ],
  ) {
    my ($label, $from, $to, $want) = @$case;
    my ($schema, $dbh) = stock('t181t', $DEFERRED, $to, $database->($from));
    my $deploy = $schema->pg_deploy;
    my $diff = $deploy->diff;
    my $sql = join "\n", @{ statements($diff) };
    like($sql, qr/DROP CONSTRAINT child_old_key;.*ADD CONSTRAINT child_code_key UNIQUE \(code\)/s, "$label: a drop and a create") or diag $sql;
    unlike($sql, qr/RENAME CONSTRAINT/, '... no rename');
    eval { $deploy->apply($diff) } or diag $@;
    is_deeply(timing($dbh), [ $want, 'child_parent_id_fkey f true true' ], '... the catalog follows');
    settled($label, $schema);
    $schema->storage->disconnect;
  }
}

done_testing;
