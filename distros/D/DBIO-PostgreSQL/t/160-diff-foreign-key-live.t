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

# LIVE test for karr k140: the diff compares and creates foreign keys.
#
# WHY it exists: the install writes a FOREIGN KEY for a belongs_to
# (pg_fk_constraints_from_rels) with its ON DELETE / ON UPDATE; the diff had no
# class for them. A table an upgrade created had no foreign key, a changed
# action was "no changes", and a key the schema does not declare stayed. The
# platform has 17 belongs_to and 26 tables with data.
#
# Claims, each against a server:
#
#  1. a table the diff creates gets the foreign key the install would have
#     made -- the same name, the same definition -- and the second diff is
#     empty (conformance case U4);
#  2. a foreign key added to tables that hold rows is an ordinary ADD
#     CONSTRAINT; with the option foreign_keys_not_valid it is NOT VALID and
#     VALIDATE CONSTRAINT follows, and rows that break it end the upgrade and
#     leave the key NOT VALID (the VALIDATE runs in a transaction of its own);
#  3. a changed action is a drop and a create under the same name;
#  4. a foreign key the schema does not declare is dropped, the summary names
#     it (U11);
#  5. a foreign key onto a unique key created in the same upgrade (U12);
#  6. a table that is dropped, and a key into it;
#  7. the refusal over a key some foreign key stands on stays.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $serial = 0;

# A schema class with one result class per entry: { Source => [ table,
# \@columns, \@primary_key, sub { my ($result_class, $schema_class) = @_; ... } ] }.
sub schema_class {
  my ($tables) = @_;
  my $name = 'T160::S' . ++$serial;
  no strict 'refs';
  for my $source (sort keys %$tables) {
    my ($table, $columns, $pk, $extra) = @{ $tables->{$source} };
    my $result = "${name}::Result::$source";
    @{"${result}::ISA"} = ('DBIO::Core');
    $result->load_components('PostgreSQL::Result');
    $result->table($table);
    $result->add_columns(map { ($_ => { data_type => 'bigint', is_nullable => 0 }) } @$columns);
    $result->set_primary_key(@$pk);
  }
  # the extras (belongs_to loads the other class) once every class is there
  for my $source (sort keys %$tables) {
    my $extra = $tables->{$source}[3] or next;
    $extra->("${name}::Result::$source", $name);
  }
  @{"${name}::ISA"} = ('DBIO::Schema');
  $name->load_components('PostgreSQL');
  $name->register_class($_ => "${name}::Result::$_") for keys %$tables;
  return $name;
}

# A child with a belongs_to onto Parent, written as a foreign key; %attrs are
# the relationship's attributes (on_delete ...).
sub child {
  my (%attrs) = @_;
  return [ 'child', [qw( id parent_id )], ['id'], sub {
    my ($result, $schema_class) = @_;
    $result->belongs_to(parent => "${schema_class}::Result::Parent", 'parent_id', {%attrs});
    $result->pg_fk_constraints_from_rels(1);
  } ];
}

my $PARENT = [ 'parent', [qw( id )], ['id'] ];

sub stock {
  my ($tag, $tables, @stock) = @_;
  my $schema = schema_class($tables)->connect(PrivatePgDatabase->create($tag), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for @stock;
  return ($schema, $dbh);
}

sub statements { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

# The foreign keys of the database as the server reads them back.
sub fks {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT conrelid::pg_catalog.regclass::text || ' ' || conname || ' ' || pg_catalog.pg_get_constraintdef(oid)
           || (CASE WHEN convalidated THEN '' ELSE ' (not validated)' END)
    FROM pg_catalog.pg_constraint WHERE contype = 'f' ORDER BY 1});
}

sub settled {
  my ($label, $schema, %deploy) = @_;
  my $diff = eval { $schema->pg_deploy(%deploy)->diff };
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

# ---------------------------------------------------------------------------
# 1. Tables the diff creates (U4)
# ---------------------------------------------------------------------------
{
  my $tables = { Parent => $PARENT, Child => child(on_delete => 'CASCADE', on_update => 'SET NULL') };
  my ($want, $want_dbh) = installed('t160w', $tables);
  note 'server ' . $want_dbh->selectrow_array('SHOW server_version');
  is_deeply(fks($want_dbh), [
      'child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id) ON UPDATE SET NULL ON DELETE CASCADE',
    ], 'an install makes the foreign key with both actions');

  my ($schema, $dbh) = stock('t160n', $tables);
  my $deploy = $schema->pg_deploy;
  my $diff = eval { $deploy->diff };
  ok($diff, 'tables to create: Deploy->diff is built (temp database, belongs_to onto a loaded class)') or diag $@;
  like(join("\n", @{ statements($diff) }),
    qr/^ALTER TABLE public\.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY \(parent_id\) REFERENCES public\.parent \(id\) ON DELETE CASCADE ON UPDATE SET NULL;$/m,
    '... the key is in the diff, with the actions');
  like($diff->summary, qr/^  \+fk: child_parent_id_fkey \(on public\.child -> public\.parent\)$/m, '... and in the summary');
  $deploy->apply($diff);
  is_deeply(fks($dbh), fks($want_dbh), '... after apply the catalog reads like the one of an install (name, columns, actions)');
  settled('tables to create', $schema);
  $schema->storage->disconnect;
  $want->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 2. Tables with rows: ordinary, and with the option NOT VALID
# ---------------------------------------------------------------------------
{
  my @tables = (
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'INSERT INTO parent SELECT g FROM generate_series(1, 20) g',
    'INSERT INTO child SELECT g, g FROM generate_series(1, 20) g',
  );
  my $classes = { Parent => $PARENT, Child => child() };

  my ($schema, $dbh) = stock('t160p', $classes, @tables);
  my $diff = $schema->pg_deploy->diff;
  is_deeply(statements($diff), [
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id);',
    ], 'rows in the tables: by default an ordinary ADD CONSTRAINT, nothing else');
  $schema->pg_deploy->apply($diff);
  is(scalar @{ fks($dbh) }, 1, '... applied');
  settled('ordinary', $schema);
  $schema->storage->disconnect;

  ($schema, $dbh) = stock('t160v', $classes, @tables);
  my $deploy = $schema->pg_deploy(foreign_keys_not_valid => 1);
  $diff = $deploy->diff;
  is_deeply(statements($diff), [
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id) NOT VALID;',
      'ALTER TABLE public.child VALIDATE CONSTRAINT child_parent_id_fkey;',
    ], 'with foreign_keys_not_valid: ADD ... NOT VALID, then VALIDATE CONSTRAINT');
  $dbh->do($_) for ($diff->operations->[0]->as_sql);
  is_deeply(fks($dbh), [
      'child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id) NOT VALID (not validated)',
    ], '... the first step leaves the key not validated (measured: convalidated false)') or diag explain fks($dbh);
  $dbh->do('ALTER TABLE child DROP CONSTRAINT child_parent_id_fkey');
  $deploy->apply($diff);
  is_deeply(fks($dbh), [
      'child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id)',
    ], '... apply runs both: the key is valid');
  settled('not valid', $schema, foreign_keys_not_valid => 1);
  $schema->storage->disconnect;

  # Rows that break the key: the upgrade ends at the VALIDATE, which runs after
  # the COMMIT of the add (karr k145): the key stays, NOT VALID.
  ($schema, $dbh) = stock('t160r', $classes, @tables, 'INSERT INTO child VALUES (100, 99)');
  $deploy = $schema->pg_deploy(foreign_keys_not_valid => 1);
  eval { $deploy->apply($deploy->diff) };
  like($@, qr/child_parent_id_fkey/, 'an orphan row: the upgrade dies at the VALIDATE, naming the key');
  is_deeply(fks($dbh), [
      'child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id) NOT VALID (not validated)',
    ], '... and the ADD CONSTRAINT before it stays, NOT VALID (its own transaction, karr k145)');
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 3. A changed action
# ---------------------------------------------------------------------------
{
  my ($want, $want_dbh) = installed('t160cw', { Parent => $PARENT, Child => child(on_delete => 'CASCADE') });
  my ($schema, $dbh) = stock('t160c', { Parent => $PARENT, Child => child(on_delete => 'CASCADE') },
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id)',
  );
  my $diff = $schema->pg_deploy->diff;
  is_deeply(statements($diff), [
      'ALTER TABLE public.child DROP CONSTRAINT child_parent_id_fkey;',
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id) ON DELETE CASCADE;',
    ], 'ON DELETE changed: a drop and a create under the name (was "no changes")');
  $schema->pg_deploy->apply($diff);
  is_deeply(fks($dbh), fks($want_dbh), '... the key reads like the one of an install');
  settled('changed action', $schema);
  $schema->storage->disconnect;
  $want->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 4. A key the schema does not declare (U11)
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t160d', { Parent => $PARENT, Child => [ 'child', [qw( id parent_id )], ['id'] ] },
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'ALTER TABLE child ADD CONSTRAINT hand_made FOREIGN KEY (parent_id) REFERENCES parent (id)',
  );
  my $diff = $schema->pg_deploy->diff;
  is_deeply(statements($diff), ['ALTER TABLE public.child DROP CONSTRAINT hand_made;'],
    'a key the schema does not declare is dropped (the last one of its table too)');
  like($diff->summary, qr/^  -fk: hand_made \(on public\.child -> public\.parent\) -- not declared by the schema, dropped$/m,
    '... and the summary names it as not declared');
  $schema->pg_deploy->apply($diff, allow_destructive => 1);   # a key the schema does not declare is dropped
  is_deeply(fks($dbh), [], '... gone');
  settled('undeclared', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 5. A key onto a unique key created in the same upgrade (U12)
# ---------------------------------------------------------------------------
{
  my $classes = {
    Parent => [ 'parent', [qw( id code )], ['id'], sub { $_[0]->add_unique_constraint(parent_code_key => ['code']) } ],
    Child  => [ 'child', [qw( id parent_code )], ['id'], sub {
      my ($result, $schema_class) = @_;
      $result->belongs_to(parent => "${schema_class}::Result::Parent", { 'foreign.code' => 'self.parent_code' });
      $result->pg_fk_constraints_from_rels(1);
    } ],
  };
  my ($schema, $dbh) = stock('t160u', $classes,
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY, code bigint NOT NULL)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_code bigint NOT NULL)',
    'INSERT INTO parent SELECT g, g FROM generate_series(1, 5) g',
    'INSERT INTO child SELECT g, g FROM generate_series(1, 5) g',
  );
  my $diff = $schema->pg_deploy->diff;
  my @sql = @{ statements($diff) };
  is(scalar(@sql), 2, 'unique key and foreign key onto it: two statements');
  like($sql[0], qr/ADD CONSTRAINT parent_code_key UNIQUE \(code\)/, '... the unique key first');
  like($sql[1], qr/ADD CONSTRAINT child_parent_code_fkey FOREIGN KEY \(parent_code\) REFERENCES public\.parent \(code\)/, '... then the key onto it');
  $schema->pg_deploy->apply($diff);
  is(scalar @{ fks($dbh) }, 1, '... the upgrade runs');
  settled('onto a new unique key', $schema);
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 6. A table that is dropped, and a key into it
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t160t', { Child => [ 'child', [qw( id parent_id )], ['id'] ] },
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id)',
    'CREATE TABLE gone (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL REFERENCES parent (id))',
  );
  my $diff = $schema->pg_deploy->diff;
  my @sql = @{ statements($diff) };
  is_deeply([ grep { /CONSTRAINT/ } @sql ], ['ALTER TABLE public.child DROP CONSTRAINT child_parent_id_fkey;'],
    'a key into a dropped table is dropped; the key of the dropped table gets no statement');
  lives_ok_apply($schema, $diff, 'the upgrade runs');
  is_deeply(fks($dbh), [], '... no key is left');
  settled('dropped tables', $schema);
  $schema->storage->disconnect;
}

sub lives_ok_apply {
  my ($schema, $diff, $name) = @_;
  my $risky = () = $diff->destructive_operations;   # the cases drop or narrow: released where the diff says so
  ok(eval { $schema->pg_deploy->apply($diff, allow_destructive => $risky ? 1 : 0); 1 }, $name) or diag $@;
}

# ---------------------------------------------------------------------------
# 7. The refusal over an index a foreign key stands on stays
# ---------------------------------------------------------------------------
{
  my ($schema, $dbh) = stock('t160k', {
      T => [ 't', [qw( id a )], ['id'], sub { $_[0]->pg_index(t_a_key => { unique => 1, columns => ['a'] }) } ],
    },
    'CREATE TABLE t (id bigint NOT NULL PRIMARY KEY, a bigint NOT NULL, CONSTRAINT t_a_key UNIQUE (a))',
    'CREATE TABLE u (id bigint NOT NULL PRIMARY KEY, t_a bigint NOT NULL REFERENCES t (a))',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  ok(!$diff, 'a constraint a foreign key stands on, to a plain index: Deploy->diff dies') or diag $diff && $diff->as_sql;
  like($@, qr/\Arefusing to diff: /, '... refused as before, not a statement the server would refuse');
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 8. What the catalog says of a key beyond its columns and actions: convalidated,
#    MATCH FULL, the column list of ON DELETE SET NULL (cols)
# ---------------------------------------------------------------------------
{
  my @tables = (
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'INSERT INTO parent SELECT g FROM generate_series(1, 20) g',
    'INSERT INTO child SELECT g, g FROM generate_series(1, 20) g',
  );
  my $classes = { Parent => $PARENT, Child => child() };

  # a key NOT VALID in the database, the schema declares it
  for my $option (0, 1) {
    my ($schema, $dbh) = stock("t160i$option", $classes, @tables,
      'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id) NOT VALID');
    my %deploy = $option ? (foreign_keys_not_valid => 1) : ();
    my $label = $option ? 'not valid in the database, with the option' : 'not valid in the database';
    my $diff = $schema->pg_deploy(%deploy)->diff;
    is_deeply(statements($diff), [ 'ALTER TABLE public.child VALIDATE CONSTRAINT child_parent_id_fkey;' ],
      "$label: VALIDATE CONSTRAINT, no drop, no create (was: no changes)");
    like($diff->summary, qr/^  ~fk: child_parent_id_fkey \(on public\.child\) validate$/m, '... named in the summary');
    $schema->pg_deploy(%deploy)->apply($diff);
    is_deeply(fks($dbh), [ 'child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id)' ],
      '... applied: the key is valid');
    settled($label, $schema, %deploy);
    $schema->storage->disconnect;
  }

  # NOT VALID with orphan rows: validating ends the upgrade, whole
  {
    my ($schema, $dbh) = stock('t160io', $classes, @tables, 'INSERT INTO child VALUES (100, 99)',
      'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id) NOT VALID');
    my $deploy = $schema->pg_deploy;
    eval { $deploy->apply($deploy->diff) };
    like($@, qr/child_parent_id_fkey/, 'an invalid key with an orphan row: the validate dies naming the key');
    $schema->storage->disconnect;
  }

  # MATCH FULL in the database, a plain key declared: dropped and created again
  {
    my ($schema, $dbh) = stock('t160m', $classes, @tables,
      'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id) MATCH FULL');
    my $diff = $schema->pg_deploy->diff;
    is_deeply(statements($diff), [
        'ALTER TABLE public.child DROP CONSTRAINT child_parent_id_fkey;',
        'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id);',
      ], 'MATCH FULL in the database, MATCH SIMPLE declared: a drop and a create (was: no changes)');
    $schema->pg_deploy->apply($diff);
    is_deeply(fks($dbh), [ 'child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id)' ], '... applied');
    settled('match full', $schema);
    $schema->storage->disconnect;
  }

  # Declared by pg_extra_ddl (the install has no attribute for them): MATCH FULL
  # and, from PostgreSQL 15, ON DELETE SET NULL (cols). The diff writes them.
  {
    my ($vs, $vdbh) = stock('t160sv', { Parent => $PARENT });
    my $setcols = $vdbh->{pg_server_version} >= 150000;
    $vs->storage->disconnect;
    $setcols or note 'server before 15: no ON DELETE SET NULL (cols)';
    my $fk = 'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id) MATCH FULL'
      . ($setcols ? ' ON DELETE SET NULL (parent_id)' : '');
    # on the class that sorts last: the extra DDL of a class follows its own table only
    my $by_hand = { Child => [ 'child', [qw( id parent_id )], ['id'] ],
      Parent => [ 'parent', ['id'], ['id'], sub { $_[0]->pg_extra_ddl($fk) } ] };

    my ($want, $want_dbh) = installed('t160xw', $by_hand);
    my ($schema, $dbh2) = stock('t160x', $by_hand);
    my $diff = $schema->pg_deploy->diff;
    like(join("\n", @{ statements($diff) }),
      $setcols
        ? qr/REFERENCES public\.parent \(id\) MATCH FULL ON DELETE SET NULL \(parent_id\);$/m
        : qr/REFERENCES public\.parent \(id\) MATCH FULL;$/m,
      'a key with MATCH FULL' . ($setcols ? ' and ON DELETE SET NULL (cols)' : '') . ' on a table the diff creates is written with them');
    $schema->pg_deploy->apply($diff);
    is_deeply(fks($dbh2), fks($want_dbh), '... the catalog reads like the one of an install');
    settled('by hand', $schema);

    # the live key is a plain one: the declared one differs, and is created in its place
    $dbh2->do('ALTER TABLE child DROP CONSTRAINT child_parent_id_fkey');
    $dbh2->do('ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent (id)');
    $diff = $schema->pg_deploy->diff;
    is(scalar(grep { /DROP CONSTRAINT child_parent_id_fkey/ } @{ statements($diff) }), 1, 'a plain key against the declared one: dropped ...');
    $schema->pg_deploy->apply($diff);
    is_deeply(fks($dbh2), fks($want_dbh), '... and created as declared');

    # what the introspection says of it
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh2)->model;
    my ($info) = @{ $model->{foreign_keys}{'public.child'} };
    is($info->{match}, 'FULL', 'the model says match FULL');
    is($info->{is_valid}, 1, '... is_valid 1');
    is_deeply($info->{on_delete_columns}, ($setcols ? ['parent_id'] : []), '... and the ON DELETE column list');
    $schema->storage->disconnect;
    $want->storage->disconnect;
  }
}

# ---------------------------------------------------------------------------
# 8. A key into a table outside the deploy is kept (Maintainer, 2026-10-21)
# ---------------------------------------------------------------------------
{
  my $class = schema_class({ Parent => $PARENT, Child => [ 'child', [qw( id parent_id ext_id )], ['id'] ] });
  $class->pg_schemas('public');
  my $schema = $class->connect(PrivatePgDatabase->create('t160h'), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for (
    'CREATE SCHEMA other',
    'CREATE TABLE other.ext (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL, ext_id bigint NOT NULL)',
    'ALTER TABLE child ADD CONSTRAINT child_ext_fkey FOREIGN KEY (ext_id) REFERENCES other.ext (id)',
    'ALTER TABLE child ADD CONSTRAINT hand_made FOREIGN KEY (parent_id) REFERENCES parent (id)',
  );
  my $diff = $schema->pg_deploy->diff;
  my @drops = grep { /CONSTRAINT/ } @{ statements($diff) };
  is_deeply(\@drops, ['ALTER TABLE public.child DROP CONSTRAINT hand_made;'],
    'the key into the table outside pg_schemas stays, the undeclared one between deployed tables goes');
  like($diff->summary, qr/^  =fk: child_ext_fkey \(on public\.child -> other\.ext\) -- kept \(target outside the deploy\)$/m,
    '... and the summary names the one kept');
  $schema->pg_deploy->apply($diff, allow_destructive => 1);
  is(scalar(grep { /child_ext_fkey/ } @{ fks($dbh) }), 1, '... it is still there after the upgrade');
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 9. The platform: belongs_to with the option left at its default, a database
#    made by hand that has only the unique indexes, rows in it
# ---------------------------------------------------------------------------
{
  # no pg_fk_constraints_from_rels call anywhere: the default is the claim
  my $belongs = sub {
    my ($result, $schema_class) = @_;
    $result->belongs_to(parent => "${schema_class}::Result::Parent", 'parent_id');
  };
  my $class = schema_class({
    Parent => $PARENT,
    Child  => [ 'child',  [qw( id parent_id )], ['id'], $belongs ],
    Other  => [ 'other',  [qw( id parent_id )], ['id'], $belongs ],
  });
  my $schema = $class->connect(PrivatePgDatabase->create('t160i'), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for (
    'CREATE TABLE parent (id bigint NOT NULL)',
    'CREATE UNIQUE INDEX parent_pkey ON parent (id)',
    'CREATE TABLE child (id bigint NOT NULL, parent_id bigint NOT NULL)',
    'CREATE UNIQUE INDEX child_pkey ON child (id)',
    'CREATE TABLE other (id bigint NOT NULL, parent_id bigint NOT NULL)',
    'CREATE UNIQUE INDEX other_pkey ON other (id)',
    'INSERT INTO parent SELECT g FROM generate_series(1, 20) g',
    'INSERT INTO child SELECT g, g FROM generate_series(1, 20) g',
    'INSERT INTO other SELECT g, g FROM generate_series(1, 20) g',
  );
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, 'the diff of the platform shape is built') or diag $@;
  my $upgraded = $diff && eval { $schema->pg_deploy->apply($diff); 1 };
  ok($upgraded, '... and one upgrade applies it') or diag $@;
  is_deeply(fks($dbh), [
      'child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id)',
      'other other_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id)',
    ], 'both belongs_to are foreign keys, without the option set anywhere');
  settled('the platform shape', $schema);
  is($dbh->selectrow_array('SELECT count(*) FROM child'), 20, '... the rows are still there');
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 10. A key onto a table outside the deploy that the schema declares onto a
#     deployed table under the same name is a redefinition, not a key kept
# ---------------------------------------------------------------------------
{
  my $class = schema_class({ Parent => $PARENT, Child => child() });
  $class->pg_schemas('public');
  my $schema = $class->connect(PrivatePgDatabase->create('t160j'), @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for (
    'CREATE SCHEMA other',
    'CREATE TABLE other.parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE parent (id bigint NOT NULL PRIMARY KEY)',
    'CREATE TABLE child (id bigint NOT NULL PRIMARY KEY, parent_id bigint NOT NULL)',
    'ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES other.parent (id)',
  );
  my $diff = $schema->pg_deploy->diff;
  is_deeply([ grep { /CONSTRAINT/ } @{ statements($diff) } ], [
      'ALTER TABLE public.child DROP CONSTRAINT child_parent_id_fkey;',
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id);',
    ], 'the key onto other.parent is dropped and the declared one onto parent created');
  unlike($diff->summary, qr/kept/, '... it is not called kept');
  $schema->pg_deploy->apply($diff);
  is_deeply(fks($dbh), ['child child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES parent(id)'],
    '... the database ends with the declared key');
  settled('the redefined key', $schema);
  $schema->storage->disconnect;
}

done_testing;
