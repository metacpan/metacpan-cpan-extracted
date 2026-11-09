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

# LIVE test for karr k121 (U2, point 1): an index behind a PRIMARY KEY,
# UNIQUE or EXCLUDE constraint.
#
# WHY it exists: the diff wrote DROP INDEX for every index the target lacks,
# and the server refuses it for an index a constraint stands on ("cannot drop
# index ... because constraint ... requires it") -- always, even when the
# constraint is simply not in the target. Measured on PG 18 (before the fix,
# databases of this file's own): a UNIQUE constraint the target lacks, an
# EXCLUDE constraint the target lacks, a UNIQUE or PRIMARY KEY whose columns
# change under the same name (the DROP INDEX, then the CREATE UNIQUE INDEX
# fails as well: the relation exists), and a constraint a foreign key of
# another table points at: each ended in the server's error, the diff after
# it still found the same work.
#
# Claims, each against a server:
#
#  1. a constraint the target lacks is dropped by ALTER TABLE ... DROP
#     CONSTRAINT, and the diff after it is empty;
#  2. a UNIQUE index without a constraint stays DROP INDEX;
#  3. a constraint the target has as a plain index of another definition is
#     dropped, and the index created in its place;
#  4. a constraint the target has too, with another definition, is dropped
#     and added again (karr k139; it was refused while the diff created no
#     constraint, karr k101): DROP CONSTRAINT, ADD CONSTRAINT of the target's
#     columns. Only an EXCLUDE constraint, whose elements the model does not
#     carry, is still refused;
#  5. a constraint a foreign key points at goes behind the foreign key the target
#     does not declare (karr k139, k140: the drops of the keys come ahead of the
#     drops of the indexes); one that is changed with the key on it is refused,
#     naming the foreign key (t/160-diff-foreign-key-live.t, section 7).

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $serial = 0;

# A schema class with one result class per entry: { Source => [ table,
# \@columns, \@primary_key, sub { my ($result_class) = @_; ... } ] }.
sub schema_class {
  my ($tables) = @_;
  my $name = 'T112::S' . ++$serial;
  no strict 'refs';
  for my $source (sort keys %$tables) {
    my ($table, $columns, $pk, $extra) = @{ $tables->{$source} };
    my $result = "${name}::Result::$source";
    @{"${result}::ISA"} = ('DBIO::Core');
    $result->load_components('PostgreSQL::Result');
    $result->table($table);
    $result->add_columns(map { ($_ => { data_type => 'bigint', is_nullable => 0 }) } @$columns);
    $result->set_primary_key(@$pk);
    $extra->($result) if $extra;
  }
  @{"${name}::ISA"} = ('DBIO::Schema');
  $name->load_components('PostgreSQL');
  $name->register_class($_ => "${name}::Result::$_") for keys %$tables;
  return $name;
}

# A private database holding @stock, and the schema class connected to it.
sub stock {
  my ($tag, $tables, @stock) = @_;
  my $schema = schema_class($tables)->connect(PrivatePgDatabase->create($tag), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for @stock;
  return ($schema, $dbh);
}

sub statements {
  my ($diff) = @_;
  return [ map { $_->as_sql } @{ $diff->operations } ];
}

# The key constraints of public.t, as "name type" (PostgreSQL 18 lists NOT NULL as well).
sub constraints {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT conname || ' ' || contype::text FROM pg_catalog.pg_constraint
    WHERE conrelid = 'public.t'::pg_catalog.regclass AND contype IN ('p', 'u', 'x', 'f') ORDER BY 1});
}

sub indexes {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT indexrelid::pg_catalog.regclass::text FROM pg_catalog.pg_index
    WHERE indrelid = 'public.t'::pg_catalog.regclass ORDER BY 1});
}

# Applies the statements one by one; returns the error of the first that
# fails, or nothing.
sub apply {
  my ($dbh, @sql) = @_;
  for my $sql (@sql) {
    eval { $dbh->do($sql); 1 } or return "$sql: $@";
  }
  return;
}

sub settled {
  my ($label, $schema) = @_;
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, "$label: the diff after it is built") or diag $@;
  ok($diff && !$diff->has_changes, "$label: ... and finds nothing left to do")
    or diag $diff && $diff->as_sql;
}

# diff dies with the refusal; returns its message.
sub refused {
  my ($label, $schema) = @_;
  my $diff  = eval { $schema->pg_deploy->diff };
  my $error = $@;
  ok(!$diff, "$label: Deploy->diff dies") or diag "the diff was built:\n" . $diff->as_sql;
  like($error, qr/\Arefusing to diff: index /, "$label: with a refusal that is about the index");
  return $error;
}

my $T = [ 't', [qw( id a b )], ['id'] ];

# ---------------------------------------------------------------------------
# 1. A constraint the target lacks
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t112u', { T => $T },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL,'
      . ' CONSTRAINT t_a_key UNIQUE (a), CONSTRAINT t_b_excl EXCLUDE USING btree (b WITH =))',
  );
  note 'server ' . $dbh->selectrow_array('SHOW server_version');

  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'unique and exclusion: Deploy->diff is built') or diag $@;
  is_deeply($diff && statements($diff),
    [ 'ALTER TABLE public.t DROP CONSTRAINT t_a_key;', 'ALTER TABLE public.t DROP CONSTRAINT t_b_excl;' ],
    'unique and exclusion: both constraints are dropped as constraints, not as indexes');
  is($diff && $diff->summary =~ /-constraint: t_a_key/ ? 1 : 0, 1, '... and the summary says constraint');
  is(apply($dbh, @{ statements($diff) }), undef, '... the server takes them');
  is_deeply(constraints($dbh), ['t_pkey p'], '... the primary key is still there');
  settled('unique and exclusion', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 2. A unique index that is no constraint's
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t112i', { T => $T },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL)',
    'CREATE UNIQUE INDEX t_a_uidx ON t (a)',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  is_deeply($diff && statements($diff), ['DROP INDEX public.t_a_uidx;'],
    'unique index: an index no constraint stands on is dropped by DROP INDEX');
  is(apply($dbh, @{ statements($diff) }), undef, '... the server takes it');
  settled('unique index', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 3. A constraint, and an index of the same name in the target
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t112c', {
      T => [ @$T[0, 1, 2], sub { $_[0]->pg_index(t_a_key => { unique => 1, columns => [qw( a b )] }) } ],
    },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL,'
      . ' CONSTRAINT t_a_key UNIQUE (a))',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'constraint to index: Deploy->diff is built') or diag $@;
  is_deeply($diff && statements($diff),
    [ 'ALTER TABLE public.t DROP CONSTRAINT t_a_key;',
      'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a, b);' ],
    'constraint to index: the constraint is dropped, the index the target has is created');
  is(apply($dbh, @{ statements($diff) }), undef, '... the server takes them');
  is_deeply(constraints($dbh), ['t_pkey p'], '... and no constraint is left behind');
  settled('constraint to index', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 4. A constraint the target has, with another definition
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t112k', { T => [ 't', [qw( id a b )], [qw( id a )] ] },
    'CREATE TABLE t (id bigint NOT NULL, a bigint NOT NULL, b bigint NOT NULL, PRIMARY KEY (id))',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'primary key: Deploy->diff is built') or diag $@;
  is_deeply($diff && statements($diff), [
      'ALTER TABLE public.t DROP CONSTRAINT t_pkey;',
      'ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY (id, a);',
    ], 'primary key: the constraint is dropped and added with the columns of the target');
  is(apply($dbh, @{ statements($diff) }), undef, '... the server takes them');
  is_deeply(constraints($dbh), ['t_pkey p'], '... and the table has its primary key again');
  settled('primary key', $schema);
  $schema->storage->disconnect;
}
{
  my ($schema, $dbh) = stock('t112q', {
      T => [ @$T[0, 1, 2], sub { $_[0]->pg_extra_ddl('ALTER TABLE t ADD CONSTRAINT t_a_key UNIQUE (a, b)') } ],
    },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL,'
      . ' CONSTRAINT t_a_key UNIQUE (a))',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'unique: Deploy->diff is built') or diag $@;
  is_deeply($diff && statements($diff), [
      'ALTER TABLE public.t DROP CONSTRAINT t_a_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE (a, b);',
    ], 'unique: the constraint is dropped and added with the columns of the target');
  is(apply($dbh, @{ statements($diff) }), undef, '... the server takes them');
  is_deeply(constraints($dbh), [ 't_a_key u', 't_pkey p' ], '... and both constraints are there');
  settled('unique', $schema);
  $schema->storage->disconnect;
}
{
  my ($schema, $dbh) = stock('t112x', {
      T => [ @$T[0, 1, 2], sub {
        $_[0]->pg_extra_ddl('ALTER TABLE t ADD CONSTRAINT t_a_excl EXCLUDE USING btree (a WITH =, b WITH =)')
      } ],
    },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL,'
      . ' CONSTRAINT t_a_excl EXCLUDE USING btree (a WITH =))',
  );
  my $error = refused('exclusion', $schema);
  like($error, qr/index t_a_excl on public\.t is the index of the EXCLUDE constraint t_a_excl/,
    'exclusion: the refusal names the index and the constraint');
  like($error, qr/^  +ALTER TABLE public\.t ADD CONSTRAINT t_a_excl EXCLUDE \(\.\.\.\);$/m,
    '... and the constraint to add, without the elements the model does not carry');
  is_deeply(constraints($dbh), [ 't_a_excl x', 't_pkey p' ], '... nothing happened');
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 5. A constraint a foreign key points at
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t112f', { T => $T, U => [ 'u', [qw( id t_a )], ['id'] ] },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL,'
      . ' CONSTRAINT t_a_key UNIQUE (a))',
    'CREATE TABLE u (id bigint NOT NULL PRIMARY KEY, t_a bigint NOT NULL CONSTRAINT u_t_a_fkey REFERENCES t (a))',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'foreign key: the target declares no key, the diff is built (it was refused)') or diag $@;
  is_deeply($diff && statements($diff), [
      'ALTER TABLE public.u DROP CONSTRAINT u_t_a_fkey;',
      'ALTER TABLE public.t DROP CONSTRAINT t_a_key;',
    ], '... it drops the foreign key, then the constraint');
  is(apply($dbh, @{ statements($diff) }), undef, '... the server takes them') if $diff;
  is_deeply(constraints($dbh), [ 't_pkey p' ], '... the constraint is gone');
  settled('foreign key', $schema);
  $schema->storage->disconnect;
}

done_testing;
