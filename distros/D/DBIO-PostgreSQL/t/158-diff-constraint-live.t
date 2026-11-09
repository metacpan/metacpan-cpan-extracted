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

# LIVE test for karr k139: the diff creates the PRIMARY KEY and UNIQUE
# constraints of a table, and repairs the database that has them as indexes.
#
# WHY it exists: install writes the key into CREATE TABLE, the diff wrote the
# index from its pg_get_indexdef text, and PostgreSQL writes the same text for
# the index of a constraint and for a unique index no constraint stands on. A
# table the diff created had no constraint (pg_constraint without contype p
# or u, nothing for a foreign key to point at in the catalog's own terms), and
# the comparison by definition never saw it: the second diff was empty. The
# platform has 26 such tables.
#
# Claims, each against a server:
#
#  1. a table the diff creates gets its PRIMARY KEY and UNIQUE as constraints,
#     the catalog reads like the one of an install, the second diff is empty;
#  2. the database an earlier diff made (tables, and the key only as a
#     CREATE UNIQUE INDEX t_pkey) is brought to the install's state with ONE
#     upgrade: ALTER TABLE ... ADD CONSTRAINT ... USING INDEX, no second
#     index, no rebuild, the index keeps its name; the second diff is empty;
#  3. a foreign key that stands on such an index stays valid;
#  4. a constraint the target has as a plain index of the same columns goes
#     the way back, and never becomes a second primary key;
#  5. UNIQUE NULLS NOT DISTINCT (PostgreSQL 15 and later) is created as it is;
#  6. a primary key under another name than the database has is refused,
#     naming the constraint to drop first (the diff creates before it drops).

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $serial = 0;

# A schema class with one result class per entry: { Source => [ table,
# \@columns, \@primary_key, sub { my ($result_class) = @_; ... } ] }.
sub schema_class {
  my ($tables) = @_;
  my $name = 'T158::S' . ++$serial;
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

# The key constraints of a table, as "name type", and its indexes.
sub constraints {
  my ($dbh, $table) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT conname || ' ' || contype::text FROM pg_catalog.pg_constraint
    WHERE conrelid = ?::pg_catalog.regclass AND contype IN ('p', 'u', 'x') ORDER BY 1}, undef, $table);
}

sub indexes {
  my ($dbh, $table) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT c.relname || ' ' || pg_catalog.pg_get_indexdef(i.indexrelid)
    FROM pg_catalog.pg_index i JOIN pg_catalog.pg_class c ON c.oid = i.indexrelid
    WHERE i.indrelid = ?::pg_catalog.regclass ORDER BY 1}, undef, $table);
}

sub oids {
  my ($dbh, $names) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT c.relname || ' ' || c.oid FROM pg_catalog.pg_class c WHERE c.relname = ANY(?) ORDER BY 1}, undef, $names);
}

sub settled {
  my ($label, $schema) = @_;
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, "$label: the diff after it is built") or diag $@;
  ok($diff && !$diff->has_changes, "$label: ... and finds nothing left to do")
    or diag $diff && $diff->as_sql;
}

# What an install makes of the same classes, in a database of its own.
sub installed {
  my ($tag, $tables) = @_;
  my ($schema, $dbh) = stock($tag, $tables);
  $schema->pg_deploy->install;
  return ($schema, $dbh);
}

my $T = [ 't', [qw( id a b )], ['id'], sub { $_[0]->add_unique_constraint(t_a_key => ['a']) } ];

# ---------------------------------------------------------------------------
# 1. A table the diff creates
# ---------------------------------------------------------------------------
{
  my ($want, $want_dbh) = installed('t158w', { T => $T });
  note 'server ' . $want_dbh->selectrow_array('SHOW server_version');
  is_deeply(constraints($want_dbh, 'public.t'), [ 't_a_key u', 't_pkey p' ], 'an install makes both constraints');

  my ($schema, $dbh) = stock('t158n', { T => $T });
  my $deploy = $schema->pg_deploy;
  my $diff = eval { $deploy->diff };
  ok($diff, 'a table to create: Deploy->diff is built') or diag $@;
  my $sql = join "\n", @{ statements($diff) };
  like($sql, qr/^ALTER TABLE public\.t ADD CONSTRAINT t_pkey PRIMARY KEY \(id\);$/m, '... the primary key is a constraint');
  like($sql, qr/^ALTER TABLE public\.t ADD CONSTRAINT t_a_key UNIQUE \(a\);$/m, '... the unique key is a constraint');
  unlike($sql, qr/CREATE (?:UNIQUE )?INDEX/, '... and no index is created beside them');
  like($diff->summary, qr/^  \+constraint: t_pkey \(on public\.t\)$/m, '... the summary says constraint');

  $deploy->apply($diff);
  is_deeply(constraints($dbh, 'public.t'), constraints($want_dbh, 'public.t'),
    '... pg_constraint reads like the one of an install (p and u)');
  is_deeply(indexes($dbh, 'public.t'), indexes($want_dbh, 'public.t'), '... and so do the indexes');
  settled('a table to create', $schema);
  $schema->storage->disconnect;
  $want->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 2. The database an earlier diff made: the keys only as indexes
# ---------------------------------------------------------------------------
{
  my ($want, $want_dbh) = installed('t158x', { T => $T });

  # What the diff used to make of these classes: the table, the key as nothing
  # but the pg_get_indexdef text of its index. No foreign key.
  my ($schema, $dbh) = stock('t158u', { T => $T },
    'CREATE TABLE t (id bigint NOT NULL, a bigint NOT NULL, b bigint NOT NULL)',
    'CREATE UNIQUE INDEX t_pkey ON public.t USING btree (id)',
    'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a)',
    q{INSERT INTO t SELECT g, g, g FROM generate_series(1, 50) g},
  );
  is_deeply(constraints($dbh, 'public.t'), [], 'the old way left no constraint');
  my @before = @{ oids($dbh, [qw( t_pkey t_a_key )]) };

  my $deploy = $schema->pg_deploy;
  my $diff = eval { $deploy->diff };
  ok($diff, 'the platform case: Deploy->diff is built') or diag $@;
  is_deeply($diff && statements($diff), [
      'ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE USING INDEX t_a_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY USING INDEX t_pkey;',
    ], '... exactly the two ADD CONSTRAINT ... USING INDEX, no index created or dropped');

  $deploy->upgrade;
  is_deeply(constraints($dbh, 'public.t'), constraints($want_dbh, 'public.t'),
    'one upgrade: pg_constraint reads like the one of an install (p and u)');
  is_deeply(indexes($dbh, 'public.t'), indexes($want_dbh, 'public.t'), '... the indexes too');
  is_deeply(oids($dbh, [qw( t_pkey t_a_key )]), \@before, '... and they are the indexes that were there (same oids, nothing rebuilt)');
  is($dbh->selectrow_array('SELECT count(*) FROM t'), 50, '... the rows are untouched');
  settled('the platform case', $schema);
  $schema->storage->disconnect;
  $want->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 3. A foreign key stands on the index
# ---------------------------------------------------------------------------
{
  # The foreign key is declared: an upgrade drops one the schema does not
  # (karr k140), and this claim is about a key that stays.
  my $U = [ 'u', [qw( id t_a )], ['id'], sub {
    (my $t = $_[0]) =~ s/::U\z/::T/;
    $_[0]->belongs_to(t => $t, { 'foreign.a' => 'self.t_a' });
    $_[0]->pg_fk_constraints_from_rels(1);
  } ];
  my ($schema, $dbh) = stock('t158f', { T => $T, U => $U },
    'CREATE TABLE t (id bigint NOT NULL, a bigint NOT NULL, b bigint NOT NULL)',
    'CREATE UNIQUE INDEX t_pkey ON public.t USING btree (id)',
    'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a)',
    'CREATE TABLE u (id bigint NOT NULL, t_a bigint NOT NULL)',
    'CREATE UNIQUE INDEX u_pkey ON public.u USING btree (id)',
    'ALTER TABLE u ADD CONSTRAINT u_t_a_fkey FOREIGN KEY (t_a) REFERENCES t (a)',
  );
  $schema->pg_deploy->upgrade;
  is_deeply(constraints($dbh, 'public.t'), [ 't_a_key u', 't_pkey p' ], 'a foreign key on the index: the constraint is put on it');
  is($dbh->selectrow_array(q{SELECT count(*) FROM pg_catalog.pg_constraint WHERE conname = 'u_t_a_fkey' AND convalidated}), 1,
    '... and the foreign key is still there and valid');
  settled('a foreign key on the index', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 4. The way back: the target has a plain index of the same columns
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t158b', {
      T => [ 't', [qw( id a b )], ['id'], sub { $_[0]->pg_index(t_a_key => { unique => 1, columns => ['a'] }) } ],
    },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL, CONSTRAINT t_a_key UNIQUE (a))',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'a constraint to a plain index: Deploy->diff is built') or diag $@;
  is_deeply($diff && statements($diff), [
      'ALTER TABLE public.t DROP CONSTRAINT t_a_key;',
      'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a);',
    ], '... the constraint goes, the create stays an index (not a second constraint)');
  $schema->pg_deploy->apply($diff);
  is_deeply(constraints($dbh, 'public.t'), ['t_pkey p'], '... only the primary key is left');
  settled('a constraint to a plain index', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 5. UNIQUE NULLS NOT DISTINCT
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t158k', {
      T => [ 't', [qw( id a b )], ['id'],
        sub { $_[0]->pg_extra_ddl('ALTER TABLE t ADD CONSTRAINT t_b_key UNIQUE NULLS NOT DISTINCT (b)') } ],
    },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, b bigint NOT NULL)',
  );
  SKIP: {
    skip 'NULLS NOT DISTINCT needs PostgreSQL 15', 5 if $dbh->{pg_server_version} < 150000;
    my $diff = eval { $schema->pg_deploy->diff };
    ok($diff, 'NULLS NOT DISTINCT: Deploy->diff is built') or diag $@;
    is_deeply($diff && statements($diff), ['ALTER TABLE public.t ADD CONSTRAINT t_b_key UNIQUE NULLS NOT DISTINCT (b);'],
      '... the constraint is created as it is declared');
    $schema->pg_deploy->apply($diff);
    is_deeply(constraints($dbh, 'public.t'), [ 't_b_key u', 't_pkey p' ], '... the server takes it');
    like(indexes($dbh, 'public.t')->[0], qr/NULLS NOT DISTINCT/, '... the index keeps it');
    settled('NULLS NOT DISTINCT', $schema);
  }
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 6. A primary key under another name
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t158p', { T => $T },
    'CREATE TABLE t (id bigint NOT NULL, a bigint NOT NULL, b bigint NOT NULL, CONSTRAINT t_old_pk PRIMARY KEY (id, a),'
      . ' CONSTRAINT t_a_key UNIQUE (a))',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  my $error = $@;
  ok(!$diff, 'another primary key name: Deploy->diff dies') or diag $diff && $diff->as_sql;
  like($error, qr/\Arefusing to diff: index t_pkey on public\.t is the index of the PRIMARY KEY constraint t_pkey/,
    '... naming the constraint the target wants');
  like($error, qr/^  +ALTER TABLE public\.t DROP CONSTRAINT t_old_pk;$/m, '... and the one to drop first');
  is_deeply(constraints($dbh, 'public.t'), [ 't_a_key u', 't_old_pk p' ], '... nothing happened');
  $dbh->do('ALTER TABLE public.t DROP CONSTRAINT t_old_pk');
  $schema->pg_deploy->upgrade;
  is_deeply(constraints($dbh, 'public.t'), [ 't_a_key u', 't_pkey p' ], '... after the drop by hand the diff makes the primary key');
  settled('another primary key name', $schema);
  $schema->storage->disconnect;
}

# the same primary key under another name is renamed (karr k139)
{
  my ($schema, $dbh) = stock('t158q', { T => $T },
    'CREATE TABLE t (id bigint NOT NULL, a bigint NOT NULL, b bigint NOT NULL, CONSTRAINT t_old_pk PRIMARY KEY (id),'
      . ' CONSTRAINT t_a_key UNIQUE (a))',
  );
  $schema->pg_deploy->upgrade;
  is_deeply(constraints($dbh, 'public.t'), [ 't_a_key u', 't_pkey p' ], 'the same primary key under another name: renamed');
  settled('renamed primary key', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 7. The platform case: bare unique indexes under rows, foreign keys declared,
#    a schema other than public (app), composite keys, a foreign key onto a
#    UNIQUE key and onto a composite one
# ---------------------------------------------------------------------------
{
  # { Source => { table, schema, cols, nullable, pk, uniq, fk, rels } }
  my $platform_class = sub {
    my ($spec) = @_;
    my $name = 'T158::P' . ++$serial;
    no strict 'refs';
    for my $source (sort keys %$spec) {
      my $t = $spec->{$source};
      my $result = "${name}::Result::$source";
      @{"${result}::ISA"} = ('DBIO::Core');
      $result->load_components('PostgreSQL::Result');
      $result->pg_schema($t->{schema}) if $t->{schema};
      $result->table($t->{table});
      $result->add_columns(map { ($_ => { data_type => 'bigint', is_nullable => ($t->{nullable}{$_} ? 1 : 0) }) } @{ $t->{cols} });
      $result->set_primary_key(@{ $t->{pk} });
      $result->add_unique_constraint($_ => $t->{uniq}{$_}) for sort keys %{ $t->{uniq} // {} };
    }
    for my $source (sort keys %$spec) {
      my $t = $spec->{$source};
      my $result = "${name}::Result::$source";
      for my $rel (@{ $t->{rels} // [] }) {
        my ($rel_name, $to, $cond, $attrs) = @$rel;
        $result->belongs_to($rel_name => "${name}::Result::$to", $cond, $attrs // {});
      }
      $result->pg_fk_constraints_from_rels(1) if $t->{fk};
    }
    @{"${name}::ISA"} = ('DBIO::Schema');
    $name->load_components('PostgreSQL');
    $name->pg_schemas(qw( public app ));
    $name->register_class($_ => "${name}::Result::$_") for keys %$spec;
    return $name;
  };

  my $spec = {
    Parent => { table => 'parent', cols => [qw( id code )], pk => ['id'], uniq => { parent_code_key => ['code'] } },
    Comp   => { table => 'comp', schema => 'app', cols => [qw( k1 k2 v )], nullable => { v => 1 }, pk => [qw( k2 k1 )] },
    Item   => { table => 'item', schema => 'app', cols => [qw( id a b )], pk => ['id'], uniq => { item_a_b_key => [qw( b a )] } },
    Child  => { table => 'child', cols => [qw( id parent_id parent_code item_a item_b r1 r2 )],
      nullable => { r1 => 1, r2 => 1 }, pk => ['id'], fk => 1, rels => [
        [ parent => 'Parent', 'parent_id', { on_delete => 'cascade', on_update => 'cascade' } ],
        [ parent_by_code => 'Parent', { 'foreign.code' => 'self.parent_code' } ],
        [ item => 'Item', { 'foreign.a' => 'self.item_a', 'foreign.b' => 'self.item_b' }, { on_delete => 'restrict' } ],
        [ comp => 'Comp', { 'foreign.k1' => 'self.r1', 'foreign.k2' => 'self.r2' } ],
      ] },
    Log    => { table => 'log', schema => 'app', cols => [qw( id child_id )], pk => ['id'], fk => 1,
      rels => [ [ child => 'Child', 'child_id' ] ] },
  };

  # constraints (p, u, f) with their definition and validity, and the indexes
  my $catalog = sub {
    my ($dbh) = @_;
    return [
      @{ $dbh->selectcol_arrayref(q{
        SELECT n.nspname || '.' || c.relname || ' ' || con.conname || ' ' || con.contype::text || ' '
               || pg_catalog.pg_get_constraintdef(con.oid) || (CASE WHEN con.convalidated THEN '' ELSE ' NOT VALID' END)
        FROM pg_catalog.pg_constraint con
        JOIN pg_catalog.pg_class c ON c.oid = con.conrelid
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname IN ('public', 'app') ORDER BY 1}) },
      @{ $dbh->selectcol_arrayref(q{
        SELECT pg_catalog.pg_get_indexdef(i.indexrelid)
        FROM pg_catalog.pg_index i JOIN pg_catalog.pg_class c ON c.oid = i.indrelid
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname IN ('public', 'app') ORDER BY 1}) },
    ];
  };

  my @old = (
    'CREATE SCHEMA app',
    'CREATE TABLE public.parent (id bigint NOT NULL, code bigint NOT NULL)',
    'CREATE UNIQUE INDEX parent_pkey ON public.parent USING btree (id)',
    'CREATE UNIQUE INDEX parent_code_key ON public.parent USING btree (code)',
    'CREATE TABLE app.comp (k1 bigint NOT NULL, k2 bigint NOT NULL, v bigint)',
    'CREATE UNIQUE INDEX comp_pkey ON app.comp USING btree (k2, k1)',
    'CREATE TABLE app.item (id bigint NOT NULL, a bigint NOT NULL, b bigint NOT NULL)',
    'CREATE UNIQUE INDEX item_pkey ON app.item USING btree (id)',
    'CREATE UNIQUE INDEX item_a_b_key ON app.item USING btree (b, a)',
    'CREATE TABLE public.child (id bigint NOT NULL, parent_id bigint NOT NULL, parent_code bigint NOT NULL,'
      . ' item_a bigint NOT NULL, item_b bigint NOT NULL, r1 bigint, r2 bigint)',
    'CREATE UNIQUE INDEX child_pkey ON public.child USING btree (id)',
    'CREATE TABLE app.log (id bigint NOT NULL, child_id bigint NOT NULL)',
    'CREATE UNIQUE INDEX log_pkey ON app.log USING btree (id)',
    'INSERT INTO parent SELECT g, g + 100 FROM generate_series(1, 20) g',
    'INSERT INTO app.comp SELECT g, g * 2, NULL FROM generate_series(1, 20) g',
    'INSERT INTO app.item SELECT g, g, g + 1 FROM generate_series(1, 20) g',
    'INSERT INTO child SELECT g, g, g + 100, g, g + 1, g, g * 2 FROM generate_series(1, 20) g',
    'INSERT INTO app.log SELECT g, g FROM generate_series(1, 20) g',
  );

  my $class = $platform_class->($spec);
  my $want = $class->connect(PrivatePgDatabase->create('t158pw'), @CONNECT);
  $want->storage->dbh->do('SET client_min_messages = warning');
  $want->pg_deploy->install;
  my $want_catalog = $catalog->($want->storage->dbh);
  is(scalar(grep { / f FOREIGN KEY / } @$want_catalog), 5, 'an install makes the five foreign keys (composite ones, onto UNIQUE, into app)');

  for my $option (0, 1) {
    my $label = 'the platform case' . ($option ? ' with foreign_keys_not_valid' : '');
    my %deploy = $option ? (foreign_keys_not_valid => 1) : ();
    my $live = $class->connect(PrivatePgDatabase->create("t158pl$option"), @CONNECT);
    my $dbh = $live->storage->dbh;
    $dbh->do('SET client_min_messages = warning');
    $dbh->do($_) for @old;

    my $deploy = $live->pg_deploy(%deploy);
    my $diff = eval { $deploy->diff };
    ok($diff, "$label: Deploy->diff is built") or diag $@;
    $diff or next;
    is(scalar(grep { /ADD CONSTRAINT \S+ FOREIGN KEY/ } @{ statements($diff) }), 5, '... five foreign keys to create');
    $deploy->apply($diff);
    is_deeply($catalog->($dbh), $want_catalog, '... one upgrade: constraints, foreign keys (validated) and indexes read like an install');
    settled($label, $live, %deploy);
    $live->storage->disconnect;
  }
  $want->storage->disconnect;
}

done_testing;
