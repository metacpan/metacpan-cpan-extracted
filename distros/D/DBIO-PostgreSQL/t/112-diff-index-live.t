use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# Folded from several live files by subject (karr k158): every old file is a
# subtest named after it, with its own private database(s) as before, and
# its helpers in a package block of its own, since named subs and the
# lexicals they close over are file-global otherwise.

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
{
  package Fold112::IndexConstraint;
  use Test::More;

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

  subtest 'diff-index-constraint' => sub {
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
  };
}

# LIVE test for the review of karr k139 and k140 (two cases the first fix got
# wrong, measured by an independent reviewer).
#
# 1. A database made by an older upgrade, or by hand, has the key as a unique
#    index under another name than the constraint the schema declares
#    (parent_code_uidx, the schema: parent_code_key), and perhaps a foreign key
#    on it. The diff built a second index and then failed on DROP INDEX
#    ("depends on index") -- the transaction went back. Now the index is renamed
#    and the constraint put on it.
# 2. A constraint a foreign key points at was refused for good. The drops of the
#    keys come ahead of the drops of the indexes, so a constraint goes when
#    the target drops or redirects the key; only a key that stays is refused.
#
# After each upgrade the second diff is empty and the constraints and indexes
# read like the ones an install of the same classes makes.
{
  package Fold112::RenameAndFkDrop;
  use Test::More;

  my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
  my $serial = 0;

  # A schema class with one result class per entry: { Source => [ table,
  # \@columns, \@primary_key, sub { my ($result_class, $schema_class) = @_; ... } ] }.
  sub schema_class {
    my ($tables) = @_;
    my $name = 'T163::S' . ++$serial;
    no strict 'refs';
    for my $source (sort keys %$tables) {
      my ($table, $columns, $pk) = @{ $tables->{$source} };
      my $result = "${name}::Result::$source";
      @{"${result}::ISA"} = ('DBIO::Core');
      $result->load_components('PostgreSQL::Result');
      $result->table($table);
      $result->add_columns(map { ($_ => { data_type => 'bigint', is_nullable => 0 }) } @$columns);
      $result->set_primary_key(@$pk);
    }
    for my $source (sort keys %$tables) {
      my $extra = $tables->{$source}[3] or next;
      $extra->("${name}::Result::$source", $name);
    }
    @{"${name}::ISA"} = ('DBIO::Schema');
    $name->load_components('PostgreSQL');
    $name->register_class($_ => "${name}::Result::$_") for keys %$tables;
    return $name;
  }

  # parent(id, code) with its key on code; child(id, <column>) with a belongs_to
  # written as a foreign key onto the column of the parent that $to names.
  sub parent { my (%o) = @_; [ 'parent', [qw( id code )], ['id'], $o{unique} ? sub { $_[0]->add_unique_constraint(parent_code_key => ['code']) } : undef ] }
  sub child {
    my ($column, $foreign) = @_;
    return [ 'child', ['id', $column], ['id'], sub {
      my ($result, $schema_class) = @_;
      $result->belongs_to(parent => "${schema_class}::Result::Parent", { "foreign.$foreign" => "self.$column" });
      $result->pg_fk_constraints_from_rels(1);
    } ];
  }
  my $CHILD_PLAIN = sub { [ 'child', ['id', $_[0]], ['id'] ] };

  sub stock {
    my ($tag, $tables, @stock) = @_;
    my $schema = schema_class($tables)->connect(PrivatePgDatabase->create($tag), @CONNECT);
    my $dbh = $schema->storage->dbh;
    $dbh->do('SET client_min_messages = warning');
    $dbh->do($_) for @stock;
    return ($schema, $dbh);
  }

  sub statements { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

  # Keys and indexes of the database as the server reads them back.
  sub catalog {
    my ($dbh) = @_;
    return [
      @{ $dbh->selectcol_arrayref(q{
        SELECT conrelid::pg_catalog.regclass::text || ' ' || conname || ' ' || contype::text || ' ' || pg_catalog.pg_get_constraintdef(oid)
        FROM pg_catalog.pg_constraint WHERE contype IN ('p', 'u', 'f') ORDER BY 1}) },
      @{ $dbh->selectcol_arrayref(q{
        SELECT pg_catalog.pg_get_indexdef(indexrelid) FROM pg_catalog.pg_index i
        JOIN pg_catalog.pg_class c ON c.oid = i.indrelid JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' ORDER BY 1}) },
    ];
  }

  # The upgrade: the statements, the apply, an empty second diff, and the
  # catalog of an install of the same classes.
  sub upgrade {
    my ($label, $tag, $tables, $stock, $want_statements) = @_;
    my ($want, $want_dbh) = stock("${tag}w", $tables);
    $want->pg_deploy->install;
    my ($schema, $dbh) = stock($tag, $tables, @$stock);
    my $deploy = $schema->pg_deploy;
    my $diff = eval { $deploy->diff };
    ok($diff, "$label: the diff is built") or diag $@;
    if ($diff) {
      is_deeply(statements($diff), $want_statements, "$label: the statements") or diag join "\n", @{ statements($diff) };
      my $risky = () = $diff->destructive_operations;   # the cases drop or narrow: released where the diff says so
      ok(eval { $deploy->apply($diff, allow_destructive => $risky ? 1 : 0); 1 }, "$label: the upgrade runs") or diag $@;
      my $again = eval { $schema->pg_deploy->diff };
      ok($again && !$again->has_changes, "$label: the second diff is empty") or diag $again ? join "\n", @{ statements($again) } : $@;
      is_deeply(catalog($dbh), catalog($want_dbh), "$label: keys and indexes read like an install of the classes");
    }
    $_->storage->disconnect for $schema, $want;
    return $diff;
  }

  my $PARENT_PLAIN = 'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY, code bigint NOT NULL)';

  subtest 'diff-index-rename-and-fk-drop' => sub {
  # ---------------------------------------------------------------------------
  # 1. The index under another name
  # ---------------------------------------------------------------------------
  {
    my $tables = { Parent => parent(unique => 1), Child => child('parent_code', 'code') };
    my $diff = upgrade('unique index under another name', 't163a', $tables, [
        $PARENT_PLAIN,
        'CREATE UNIQUE INDEX parent_code_uidx ON parent (code)',
        'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)',
        'INSERT INTO parent SELECT g, g FROM generate_series(1, 5) g',
        'INSERT INTO child SELECT g, g FROM generate_series(1, 5) g',
      ], [
        'ALTER INDEX public.parent_code_uidx RENAME TO parent_code_key;',
        'ALTER TABLE public.parent ADD CONSTRAINT parent_code_key UNIQUE USING INDEX parent_code_key;',
        'ALTER TABLE public.child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES public.parent (code);',
      ]);
    like($diff->summary, qr/^  ~index: parent_code_uidx -> parent_code_key \(on public\.parent\)$/m, '... the summary says the rename')
      if $diff;

    # the foreign key is on the old index already: it stays on it
    $diff = upgrade('foreign key on the index under another name', 't163c', $tables, [
        $PARENT_PLAIN,
        'CREATE UNIQUE INDEX parent_code_uidx ON parent (code)',
        'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)',
        'ALTER TABLE child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES parent (code)',
      ], [
        'ALTER INDEX public.parent_code_uidx RENAME TO parent_code_key;',
        'ALTER TABLE public.parent ADD CONSTRAINT parent_code_key UNIQUE USING INDEX parent_code_key;',
      ]);

    # a primary key
    my $pk_tables = { Parent => [ 'parent', ['id'], ['id'] ], Child => child('parent_id', 'id') };
    upgrade('primary key index under another name', 't163b', $pk_tables, [
        'CREATE TABLE parent (id bigint NOT NULL)',
        'CREATE UNIQUE INDEX parent_id_uidx ON parent (id)',
        'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
        'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id)',
      ], [
        'ALTER INDEX public.parent_id_uidx RENAME TO parent_pkey;',
        'ALTER TABLE public.parent ADD CONSTRAINT parent_pkey PRIMARY KEY USING INDEX parent_pkey;',
      ]);
  }

  # ---------------------------------------------------------------------------
  # 2. A constraint a foreign key points at, and the target drops or moves the key
  # ---------------------------------------------------------------------------
  my @WITH_KEY = (
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY, code bigint NOT NULL, CONSTRAINT parent_code_key UNIQUE (code))',
  );
  {
    # belongs_to and its UNIQUE removed together
    upgrade('belongs_to and UNIQUE removed', 't163d', { Parent => parent(), Child => $CHILD_PLAIN->('parent_code') }, [
        @WITH_KEY,
        'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)',
        'ALTER TABLE child ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY (parent_code) REFERENCES parent (code)',
      ], [
        'ALTER TABLE public.child DROP CONSTRAINT child_parent_code_fkey;',
        'ALTER TABLE public.parent DROP CONSTRAINT parent_code_key;',
      ]);

    # the key moves from code to id, UNIQUE on code removed
    upgrade('key moved from code to id', 't163e', { Parent => parent(), Child => child('p', 'id') }, [
        @WITH_KEY,
        'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, p bigint NOT NULL)',
        'ALTER TABLE child ADD CONSTRAINT child_p_fkey FOREIGN KEY (p) REFERENCES parent (code)',
      ], [
        'ALTER TABLE public.child DROP CONSTRAINT child_p_fkey;',
        'ALTER TABLE public.child ADD CONSTRAINT child_p_fkey FOREIGN KEY (p) REFERENCES public.parent (id);',
        'ALTER TABLE public.parent DROP CONSTRAINT parent_code_key;',
      ]);

    # the referenced column goes with its key
    upgrade('referenced column dropped with its key', 't163f',
      { Parent => [ 'parent', ['id'], ['id'] ], Child => $CHILD_PLAIN->('p') }, [
        @WITH_KEY,
        'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, p bigint NOT NULL)',
        'ALTER TABLE child ADD CONSTRAINT child_p_fkey FOREIGN KEY (p) REFERENCES parent (code)',
      ], [
        'ALTER TABLE public.child DROP CONSTRAINT child_p_fkey;',
        'ALTER TABLE public.parent DROP CONSTRAINT parent_code_key;',
        'ALTER TABLE public.parent DROP COLUMN code;',
      ]);
  }
  };
}

# LIVE test for karr k146: an index on a partitioned table.
#
# WHAT IT ASSERTS: the diff creates the index of a partitioned table so that it
# is valid -- at the table and at every partition, a partition that is
# partitioned itself included -- and a second diff is empty.
#
# WHY: pg_get_indexdef writes such an index ON ONLY, and an index made from
# that text is invalid until the partitions have indexes attached.
{
  package Fold112::Partitioned;
  use Test::More;

  my ($dbh_a, $dbh_b);

  sub catalog {
    my ($dbh) = @_;
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
    delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
    return $model;
  }

  sub diff_of { DBIO::PostgreSQL::Diff->new(source => catalog($_[0]), target => catalog($_[1])) }
  sub sql_of  { [ map { split /\n/, $_->as_sql } @{ $_[0]->operations } ] }

  sub start_over {
    my ($sql_a, $sql_b) = @_;
    for my $dbh ($dbh_a, $dbh_b) {
      $dbh->do($_) for 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
    }
    $dbh_a->do($_) for @$sql_a;
    $dbh_b->do($_) for @$sql_b;
  }

  # every index of the tree below public.pt: name => validity, copies included
  sub validity {
    my ($dbh) = @_;
    return $dbh->selectall_hashref(q{
      SELECT c.relname AS name, i.indisvalid AS valid, i.indrelid::regclass::text AS tab
      FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND i.indrelid::regclass::text LIKE 'pt%'
    }, 'name');
  }

  sub runs_and_settles {
    my ($label, $diff, $count) = @_;
    $dbh_a->begin_work;
    ok(eval { $dbh_a->do($_) for @{ sql_of($diff) }; $dbh_a->commit; 1 }, "$label: the statements run")
      or do { diag $@; $dbh_a->rollback };
    my $valid = validity($dbh_a);
    is(scalar(keys %$valid), $count, "$label: $count indexes in the tree") or diag join ' ', sort keys %$valid;
    is_deeply([ grep { !$valid->{$_}{valid} } sort keys %$valid ], [], "$label: every index of the tree is valid");
    is_deeply(sql_of(diff_of($dbh_a, $dbh_b)), [], "$label: the second diff is empty");
  }

  subtest 'diff-index-partitioned' => sub {
  ($dbh_a, $dbh_b) = map {
    my $h = LiveServer->control_dbh(
      login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
    $h->do('SET client_min_messages = warning');
    $h;
  } qw( t180a t180b );

  my @tables = (
    'CREATE TABLE public.pt (id integer NOT NULL, tag text, grp integer NOT NULL) PARTITION BY RANGE (id)',
    'CREATE TABLE public.pt1 PARTITION OF public.pt FOR VALUES FROM (0) TO (100)',
    'CREATE TABLE public.pt2 PARTITION OF public.pt FOR VALUES FROM (100) TO (200) PARTITION BY LIST (grp)',
    'CREATE TABLE public.pt2a PARTITION OF public.pt2 FOR VALUES IN (1)',
    'CREATE TABLE public.pt2b PARTITION OF public.pt2 FOR VALUES IN (2)',
  );

  # The text alone is invalid: the claim the fix stands on.
  start_over([@tables, 'CREATE INDEX pt_tag ON pt (tag)'], []);
  like(catalog($dbh_a)->{indexes}{'public.pt'}{pt_tag}{definition}, qr/ON ONLY public\.pt /,
    'the catalog writes the index of a partitioned table ON ONLY');

  # A plain index, two levels of partitions.
  start_over([@tables], [ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ]);
  {
    my $diff = diff_of($dbh_a, $dbh_b);
    like(join("\n", @{ sql_of($diff) }), qr/ATTACH PARTITION/, 'create: the partitions are attached');
    runs_and_settles("create", $diff, 5);
  }

  # Unique (the key of the partitions included), partial, expression.
  start_over([@tables], [ @tables,
    'CREATE UNIQUE INDEX pt_u ON public.pt (id, grp, tag)',
    'CREATE INDEX pt_part ON public.pt (grp) WHERE grp > 0',
    'CREATE INDEX pt_expr ON public.pt (lower(tag))',
    'CREATE INDEX pt_tag ON public.pt (tag)',
  ]);
  runs_and_settles('unique, partial, expression, same columns twice', diff_of($dbh_a, $dbh_b), 20);

  # A changed index: dropped, created again, valid.
  start_over([ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ], [ @tables, 'CREATE INDEX pt_tag ON public.pt (tag, grp)' ]);
  runs_and_settles('changed', diff_of($dbh_a, $dbh_b), 5);

  # Equal databases: nothing.
  start_over([ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ], [ @tables, 'CREATE INDEX pt_tag ON public.pt (tag)' ]);
  is_deeply(sql_of(diff_of($dbh_a, $dbh_b)), [], 'the same index on both sides: no operation');
  };
}

done_testing;
