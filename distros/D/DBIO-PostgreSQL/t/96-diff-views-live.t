use strict;
use warnings;

use Test::More;
use Test::Exception;

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

# LIVE test for karr k100: what the diff creates is what the target has.
#
# WHY it exists: t/94, t/95 and t/06 pin the statements; only a server says
# whether they are statements, and whether what they make is the thing the
# target has. The diff used to build every relation as a table and every
# column from the parts of the model it knew, and the result was something
# else than the target: a table where the schema declares a view, a DROP TABLE
# the server refuses for a view, a generated column written as a DEFAULT, a
# restrictive policy for one role created permissive for everybody, a new
# table whose row level security came with the next diff.
#
# Two ways of asking, both in databases of this file's own (karr k81):
#
#  * through Deploy, with a schema that declares a view -- install, the view
#    arriving in an upgrade, changing, going;
#  * model against model, for what no class can declare: one database is made
#    into another by the diff between them, and afterwards the catalog of the
#    one reads like the catalog of the other.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------
{
  package T96::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_nullable => 0 },
    a     => { data_type => 'integer', is_nullable => 1 },
    label => { data_type => 'text',    is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

# A result class for a view that is deployed (not virtual).
sub view_class {
  my ($class, $name, $definition, @columns) = @_;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(map { $_ => { data_type => 'integer', is_nullable => 1 } } @columns);
  $class->result_source_instance->view_definition($definition);
  return $class;
}

sub schema_class {
  my ($class, %results) = @_;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->register_class($_ => $results{$_}) for sort keys %results;
  return $class;
}

my %ITEM = ( Item => 'T96::Result::Item' );

schema_class('T96::Plain', %ITEM);
schema_class('T96::WithView', %ITEM,
  Positive => view_class('T96::Result::Positive', positive =>
    'SELECT id, a FROM item WHERE a > 0', qw( id a )));
schema_class('T96::ViewChanged', %ITEM,
  Positive => view_class('T96::Result::PositiveChanged', positive =>
    'SELECT id, a FROM item WHERE a > 10', qw( id a )));

# Two views, one on the other. install_ddl writes views in the order of their
# source names, so those are in the order of dependency (V1, V2); the views'
# own names are not: by name, a_top comes before the z_base it reads.
my $TOP = view_class('T96::Result::Top', a_top =>
  'SELECT id FROM z_base WHERE a > 0', qw( id ));
schema_class('T96::Stacked', %ITEM, V2Top => $TOP,
  V1Base => view_class('T96::Result::Base', z_base =>
    'SELECT id, a FROM item', qw( id a )));
schema_class('T96::StackedChanged', %ITEM, V2Top => $TOP,
  V1Base => view_class('T96::Result::BaseChanged', z_base =>
    'SELECT id, a FROM item WHERE a IS NOT NULL', qw( id a )));

# A view in a schema of its own, on a table in it, and that schema on the
# declared search_path.
{
  package T96::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_nullable => 0 },
    a  => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
schema_class('T96::Path', User => 'T96::Result::User',
  Active => view_class('T96::Result::Active', active =>
    'SELECT id FROM auth.users WHERE a > 0', 'id'));
T96::Result::Active->pg_schema('auth');
T96::Path->pg_schemas(qw( public auth ));
T96::Path->pg_search_path(qw( auth public ));

# A table with row level security and policies. pg_rls cannot say AS
# RESTRICTIVE, so that policy is raw DDL; it is for the role of the
# connection, which is the one role that is certain to exist.
{
  package T96::Result::Guarded;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('guarded');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_nullable => 0 },
    owner => { data_type => 'text',    is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_rls({
    enable   => 1,
    policies => {
      everybody => { for => 'SELECT', roles => ['PUBLIC'], using => 'true' },
    },
  });
  __PACKAGE__->pg_extra_ddl(
    'CREATE POLICY own_rows ON guarded AS RESTRICTIVE FOR SELECT TO CURRENT_USER'
    . ' USING (owner = CURRENT_USER)',
  );
}
schema_class('T96::WithGuarded', %ITEM, Guarded => 'T96::Result::Guarded');

# A table with generated columns. No column declaration says "generated", so
# they are raw DDL as well.
sub generated_class {
  my ($class, @extra_ddl) = @_;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('priced');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_nullable => 0 },
      net  => { data_type => 'integer', is_nullable => 0 },
      name => { data_type => 'text',    is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@;
  $class->pg_extra_ddl(@extra_ddl);
  return $class;
}
my @STORED = (
  'ALTER TABLE priced ADD COLUMN gross integer GENERATED ALWAYS AS (net * 2) STORED NOT NULL',
  'ALTER TABLE priced ADD COLUMN lname text GENERATED ALWAYS AS (lower(name)) STORED',
);
schema_class('T96::Generated', %ITEM,
  Priced => generated_class('T96::Result::Priced', @STORED));
schema_class('T96::GeneratedVirtual', %ITEM,
  Priced => generated_class('T96::Result::PricedVirtual', @STORED,
    'ALTER TABLE priced ADD COLUMN triple integer GENERATED ALWAYS AS (net * 3) VIRTUAL'));
schema_class('T96::GeneratedOtherwise', %ITEM,
  Priced => generated_class('T96::Result::PricedOtherwise',
    'ALTER TABLE priced ADD COLUMN gross integer GENERATED ALWAYS AS (net * 5) STORED NOT NULL',
    $STORED[1]));

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub relkind {
  my ($dbh, $name) = @_;
  my ($kind) = $dbh->selectrow_array(q{
    SELECT c.relkind FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = ?}, undef, $name);
  return $kind;
}

# The statements of a diff, one per operation.
sub statements {
  my ($diff) = @_;
  return [ map { $_->as_sql } @{ $diff->operations } ];
}

# The same schema classes against the database $dbh is connected to.
sub upgrade_to {
  my ($label, $class, $connect) = @_;
  my $schema = $class->connect(@$connect, @CONNECT);
  my $deploy = $schema->pg_deploy;

  my $diff = eval { $deploy->diff };
  ok($diff, "$label: the diff is built") or do { diag $@; return ($schema, []) };
  my $statements = statements($diff);
  note join "\n", @$statements;

  my $risky = () = $diff->destructive_operations;   # the cases drop or narrow: released where the diff says so
  ok(eval { $deploy->apply($diff, allow_destructive => $risky ? 1 : 0); 1 }, "$label: apply runs through")
    or diag "$@\n" . $diff->as_sql;

  my $again = $deploy->diff;
  ok(!$again->has_changes, "$label: a second diff finds nothing left to do")
    or diag $again->as_sql;

  return ($schema, $statements);
}

sub server_refuses {
  my ($dbh, $sql, $expect, $why) = @_;
  $dbh->begin_work;
  my $ok = eval { $dbh->do($sql); 1 };
  my $error = $@;
  $dbh->rollback;
  ok(!$ok && $error =~ $expect, $why) or diag($ok ? "$sql ran through" : $error);
}

my ($version_num, $server_version);
{
  my $h = LiveServer->control_dbh;
  ($version_num)    = $h->selectrow_array('SHOW server_version_num');
  ($server_version) = $h->selectrow_array('SHOW server_version');
  $h->disconnect;
  note "server $server_version";
}

# ---------------------------------------------------------------------------
# 1. A declared view through its life: installed, arriving, changing, going
# ---------------------------------------------------------------------------
{
  my @db = PrivatePgDatabase->create('t96inst');
  my $schema = T96::WithView->connect(@db, @CONNECT);
  $schema->pg_deploy->install;
  is(relkind($schema->storage->dbh, 'positive'), 'v', 'install makes the declared view a view');
  ok(!$schema->pg_deploy->diff->has_changes,
    'and the diff of what was just installed finds nothing to do')
    or diag $schema->pg_deploy->diff->as_sql;
  $schema->storage->disconnect;
}

{
  my @db = PrivatePgDatabase->create('t96life');
  my $plain = T96::Plain->connect(@db, @CONNECT);
  $plain->pg_deploy->install;
  my $dbh = $plain->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do('INSERT INTO item (id, a) VALUES (1, -5), (2, 5), (3, 50)');
  is(relkind($dbh, 'positive'), undef, 'precondition: the database has no relation "positive"');

  # arriving
  my ($with, $statements) = upgrade_to('a view that comes in an upgrade', 'T96::WithView', \@db);
  is(scalar @$statements, 1, 'one statement');
  like($statements->[0], qr/\ACREATE VIEW public\.positive AS /, 'CREATE VIEW');
  is(relkind($dbh, 'positive'), 'v', 'what the upgrade made is a view, not a table');
  is_deeply($dbh->selectcol_arrayref('SELECT id FROM positive ORDER BY id'), [ 2, 3 ],
    'and it reads the table as its definition says');
  $with->storage->disconnect;

  # changing
  server_refuses($dbh, 'ALTER TABLE positive ADD COLUMN z integer', qr/not supported for views/,
    'precondition: PostgreSQL has no ALTER TABLE ... ADD COLUMN for a view');
  my $changed;
  ($changed, $statements) = upgrade_to('a view with another definition', 'T96::ViewChanged', \@db);
  is(scalar @$statements, 2, 'two statements');
  is($statements->[0], 'DROP VIEW public.positive;', 'DROP VIEW');
  like($statements->[1], qr/\ACREATE VIEW public\.positive AS .*> 10/s, 'and CREATE VIEW with the new definition');
  is(relkind($dbh, 'positive'), 'v', 'it is still a view');
  is_deeply($dbh->selectcol_arrayref('SELECT id FROM positive ORDER BY id'), [ 3 ],
    'with the new definition');
  $changed->storage->disconnect;

  # going
  server_refuses($dbh, 'DROP TABLE positive CASCADE', qr/is not a table/,
    'precondition: PostgreSQL does not drop a view with DROP TABLE');
  my $gone;
  ($gone, $statements) = upgrade_to('a view that is no longer declared', 'T96::Plain', \@db);
  is_deeply($statements, [ 'DROP VIEW public.positive;' ], 'DROP VIEW, and nothing else');
  is(relkind($dbh, 'positive'), undef, 'the view is gone');
  is($dbh->selectrow_array('SELECT count(*) FROM item'), 3, 'the table it read has its rows');
  $_->storage->disconnect for $gone, $plain;
}

# A definition means the same in every session. pg_get_viewdef writes a name
# without its schema when the search_path of the asking session finds it. The
# temporary database is read under the declared path (the connection sets it),
# the database itself under whatever its connection has; read that way, the
# view below differed from itself on every diff of a connection with another
# path, and was "changed" to SELECT ... FROM users -- a statement that finds
# no table there, or the wrong one.
{
  my @db = PrivatePgDatabase->create('t96path');
  my $installer = T96::Path->connect(@db, @CONNECT);
  $installer->pg_deploy->install;
  $installer->storage->disconnect;

  my $schema = T96::Path->connect(@db, @CONNECT);
  my $dbh = $schema->storage->dbh;
  $dbh->do('SET search_path TO public');   # a session whose path is not the declared one
  unlike($dbh->selectrow_array('SHOW search_path'), qr/\bauth\b/,
    'precondition: the connection has another search_path than the declared one');

  my $diff = $schema->pg_deploy->diff;
  ok(!$diff->has_changes, 'the view is the same view in a later connection')
    or diag $diff->as_sql;

  for my $path ('auth, public', 'public') {
    $dbh->do("SET search_path TO $path");
    my $definition = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)
      ->model->{tables}{'auth.active'}{view_definition};
    like($definition, qr/\bFROM auth\.users\b/,
      "under search_path $path the definition names the table with its schema");
    is($dbh->selectrow_array('SHOW search_path'), $path,
      '... and the session has the search_path it had');
  }
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 2. A view on a view
# ---------------------------------------------------------------------------
{
  my @db = PrivatePgDatabase->create('t96stack');
  my $plain = T96::Plain->connect(@db, @CONNECT);
  $plain->pg_deploy->install;
  my $dbh = $plain->storage->dbh;
  $dbh->do('SET client_min_messages = warning');

  my ($stacked, $statements) = upgrade_to('two views, one on the other', 'T96::Stacked', \@db);
  is(scalar @$statements, 2, 'two statements');
  like($statements->[0], qr/\ACREATE VIEW public\.z_base /, 'the view that is read comes first');
  like($statements->[1], qr/\ACREATE VIEW public\.a_top /,  'the view that reads it second, against the order of the names');
  is_deeply(
    DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model->{tables}{'public.a_top'}{depends_on},
    [ 'public.z_base' ],
    'the model has from the catalog what a_top reads');
  $stacked->storage->disconnect;

  # Undeclared, on top of the declared ones: a materialized view with an
  # index on a_top, and a view on z_base.
  $dbh->do($_) for (
    'CREATE MATERIALIZED VIEW public.old_mv AS SELECT id FROM public.a_top',
    'CREATE INDEX old_mv_idx ON public.old_mv (id)',
    'CREATE VIEW public.old_v AS SELECT a FROM public.z_base',
  );
  server_refuses($dbh, 'DROP VIEW public.z_base', qr/other objects depend on it/,
    'precondition: PostgreSQL does not drop a view another view depends on');

  # z_base changes; a_top, which is declared as before, stands on it.
  my $changed;
  ($changed, $statements) = upgrade_to('a changed view under an unchanged one', 'T96::StackedChanged', \@db);
  my %at = map { ($statements->[$_] =~ /\A(\w+(?: MATERIALIZED)? \w+ \S+?);?(?: |\z)/)[0] => $_ } 0 .. $#$statements;
  is_deeply([ sort keys %at ], [
    'CREATE VIEW public.a_top',
    'CREATE VIEW public.z_base',
    'DROP MATERIALIZED VIEW public.old_mv',
    'DROP VIEW public.a_top',
    'DROP VIEW public.old_v',
    'DROP VIEW public.z_base',
  ], 'everything on the changed view makes way, and what is declared comes back')
    or diag explain $statements;
  for my $order (
    [ 'DROP MATERIALIZED VIEW public.old_mv', 'DROP VIEW public.a_top',    'the materialized view goes before the view it reads' ],
    [ 'DROP VIEW public.a_top',               'DROP VIEW public.z_base',   'the unchanged view goes before the changed one it reads' ],
    [ 'DROP VIEW public.old_v',               'DROP VIEW public.z_base',   'and so does the undeclared one' ],
    [ 'DROP VIEW public.z_base',              'CREATE VIEW public.z_base', 'the changed view is dropped, then created' ],
    [ 'CREATE VIEW public.z_base',            'CREATE VIEW public.a_top',  'and the view on it after it' ],
  ) {
    my ($first, $then, $why) = @$order;
    cmp_ok($at{$first} // 99, '<', $at{$then} // -1, $why);
  }
  is(relkind($dbh, $_), 'v', "$_ is a view again") for qw( z_base a_top );
  is(relkind($dbh, $_), undef, "the undeclared $_ is gone") for qw( old_mv old_v );
  $changed->storage->disconnect;

  my $gone;
  ($gone, $statements) = upgrade_to('both views no longer declared', 'T96::Plain', \@db);
  is_deeply($statements, [ 'DROP VIEW public.a_top;', 'DROP VIEW public.z_base;' ],
    'the view that reads is dropped before the view that is read');
  $_->storage->disconnect for $gone, $plain;
}

# ---------------------------------------------------------------------------
# 3. What the schema does not declare: a materialized view, a table where the
#    schema has a view
# ---------------------------------------------------------------------------
{
  my @db = PrivatePgDatabase->create('t96mv');
  my $plain = T96::Plain->connect(@db, @CONNECT);
  $plain->pg_deploy->install;
  my $dbh = $plain->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  $dbh->do($_) for (
    'INSERT INTO item (id, a) VALUES (1, 1), (2, 1)',
    'CREATE MATERIALIZED VIEW public.item_totals AS SELECT a, count(*) AS n FROM public.item GROUP BY a',
    'CREATE INDEX item_totals_a_idx ON public.item_totals (a)',
  );
  server_refuses($dbh, 'DROP TABLE public.item_totals CASCADE', qr/is not a table/,
    'precondition: PostgreSQL does not drop a materialized view with DROP TABLE');

  my ($schema, $statements) = upgrade_to('an undeclared materialized view', 'T96::Plain', \@db);
  is_deeply($statements, [ 'DROP MATERIALIZED VIEW public.item_totals;' ],
    'DROP MATERIALIZED VIEW; its index goes with it');
  is(relkind($dbh, 'item_totals'), undef, 'the materialized view is gone');
  is($dbh->selectrow_array('SELECT count(*) FROM item'), 2, 'the table it read has its rows');
  $schema->storage->disconnect;

  # A table called like the declared view. Making it a view means dropping
  # the table.
  $dbh->do($_) for (
    'CREATE TABLE public.positive (id integer, a integer)',
    'INSERT INTO public.positive VALUES (7, 7)',
  );
  my $with = T96::WithView->connect(@db, @CONNECT);
  throws_ok { $with->pg_deploy->diff }
    qr/\Arefusing to diff: public\.positive is a table in the database and a view in the target/,
    'a table where the schema declares a view is refused when the diff is built';
  is(relkind($dbh, 'positive'), 'r', 'the table is still a table');
  is($dbh->selectrow_array('SELECT count(*) FROM positive'), 1, 'with its row');
  $_->storage->disconnect for $with, $plain;
}

# ---------------------------------------------------------------------------
# 4. Generated columns, through Deploy
# ---------------------------------------------------------------------------
{
  my $virtual = $version_num >= 180000;
  my $class   = $virtual ? 'T96::GeneratedVirtual' : 'T96::Generated';
  note 'virtual generated columns need PostgreSQL 18; this server has '
    . ($virtual ? 'them' : 'none, the stored ones are tested alone');

  my @db = PrivatePgDatabase->create('t96gen');
  my $plain = T96::Plain->connect(@db, @CONNECT);
  $plain->pg_deploy->install;
  my $dbh = $plain->storage->dbh;
  $dbh->do('SET client_min_messages = warning');

  my ($schema, $statements) = upgrade_to('a new table with generated columns', $class, \@db);
  my ($create) = grep { /\ACREATE TABLE public\.priced / } @$statements;
  ok($create, 'the diff creates the table') or diag explain $statements;
  like($create, qr/gross integer NOT NULL GENERATED ALWAYS AS \(\(net \* 2\)\) STORED/,
    'with the stored generated column as one');
  like($create, qr/lname text GENERATED ALWAYS AS \(lower\(name\)\) STORED/,
    'the expression in parentheses of the diff\'s own where the catalog has none');
  like($create, qr/triple integer GENERATED ALWAYS AS \(\(net \* 3\)\) VIRTUAL/,
    'and the virtual one as one') if $virtual;

  is_deeply(
    $dbh->selectall_arrayref(q{
      SELECT a.attname, a.attgenerated FROM pg_catalog.pg_attribute a
      WHERE a.attrelid = 'public.priced'::pg_catalog.regclass
        AND a.attnum > 0 AND NOT a.attisdropped AND a.attgenerated <> ''
      ORDER BY a.attname}),
    [ [ gross => 's' ], [ lname => 's' ], ($virtual ? [ triple => 'v' ] : ()) ],
    'the catalog has them as generated columns');

  $dbh->do(q{INSERT INTO priced (id, net, name) VALUES (1, 21, 'ABC')});
  is_deeply(
    [ $dbh->selectrow_array('SELECT gross, lname' . ($virtual ? ', triple' : '') . ' FROM priced') ],
    [ 42, 'abc', ($virtual ? 63 : ()) ],
    'and they compute');
  server_refuses($dbh, 'ALTER TABLE priced ALTER COLUMN gross SET DEFAULT (net * 5)',
    qr/is a generated column/,
    'precondition: PostgreSQL has no SET DEFAULT for a generated column');
  $schema->storage->disconnect;

  # Another expression for a column that is there.
  my $otherwise = T96::GeneratedOtherwise->connect(@db, @CONNECT);
  throws_ok { $otherwise->pg_deploy->diff }
    qr/\Arefusing to diff: column public\.priced\.gross is generated from \(net \* 2\) in the database and from \(net \* 5\) in the target/,
    'a generated column with another expression is refused when the diff is built';
  is($dbh->selectrow_array('SELECT gross FROM priced'), 42, 'the column is as it was');
  $_->storage->disconnect for $otherwise, $plain;
}

# ---------------------------------------------------------------------------
# 5. A new table with row level security and policies, through Deploy
# ---------------------------------------------------------------------------
{
  my @db = PrivatePgDatabase->create('t96rls');
  my $plain = T96::Plain->connect(@db, @CONNECT);
  $plain->pg_deploy->install;
  my $dbh = $plain->storage->dbh;
  $dbh->do('SET client_min_messages = warning');
  my ($role) = $dbh->selectrow_array('SELECT current_user');

  my ($schema, $statements) = upgrade_to('a new table with row level security', 'T96::WithGuarded', \@db);

  my %at = map { ($statements->[$_] =~ /\A(CREATE TABLE|ALTER TABLE \S+ ENABLE|CREATE POLICY \w+)/)[0] // '' => $_ }
    0 .. $#$statements;
  ok(defined $at{'ALTER TABLE public.guarded ENABLE'},
    'row level security is enabled in the diff that creates the table')
    or diag explain $statements;
  cmp_ok($at{'CREATE TABLE'}, '<', $at{'ALTER TABLE public.guarded ENABLE'} // -1,
    '... after the table is created');

  my ($own) = grep { /\ACREATE POLICY own_rows / } @$statements;
  like($own, qr/ AS RESTRICTIVE FOR SELECT TO \Q$role\E USING /,
    'the restrictive policy is created restrictive and for its role')
    or diag explain $statements;

  is($dbh->selectrow_array(
    q{SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.guarded'::pg_catalog.regclass}),
    1, 'the table has row level security');
  is_deeply(
    $dbh->selectall_arrayref(q{
      SELECT p.polname, p.polpermissive,
             (SELECT string_agg(CASE WHEN r = 0 THEN 'PUBLIC' ELSE r::pg_catalog.regrole::text END, ',')
                FROM unnest(p.polroles) AS r)
      FROM pg_catalog.pg_policy p
      WHERE p.polrelid = 'public.guarded'::pg_catalog.regclass ORDER BY 1}),
    [ [ everybody => 1, 'PUBLIC' ], [ own_rows => 0, $role ] ],
    'the catalog has each policy with its kind and its roles');
  $_->storage->disconnect for $schema, $plain;
}

# ---------------------------------------------------------------------------
# 6. Model against model: one database made into another
# ---------------------------------------------------------------------------

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t96a t96b );

# A model without what differs between any two databases.
sub catalog {
  my ($dbh) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

sub start_over {
  for my $dbh ($dbh_a, $dbh_b) {
    $dbh->do($_) for (
      'DROP SCHEMA public CASCADE',
      'CREATE SCHEMA public',
      'DROP FOREIGN DATA WRAPPER IF EXISTS t96_fdw CASCADE',
    );
  }
}

# Database A is built from @$sql_a, database B from @$sql_b, and A is made
# into B with the diff between them. Returns the statements.
#
# A table the diff has to create has no PRIMARY KEY in these cases: the diff
# knows a primary key only as its index (karr k101), so the two catalogs
# would differ in something this file is not about.
sub becomes {
  my ($label, $sql_a, $sql_b) = @_;
  start_over();
  $dbh_a->do($_) for @$sql_a;
  $dbh_b->do($_) for @$sql_b;

  my $target = catalog($dbh_b);
  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => $target);
  my $statements = eval { statements($diff) };
  ok($statements, "$label: the diff is built") or do { diag $@; return [] };
  note join "\n", @$statements;

  $dbh_a->begin_work;
  ok(eval { $dbh_a->do($_) for @$statements; $dbh_a->commit; 1 }, "$label: the statements run")
    or do { diag $@; $dbh_a->rollback; return $statements };

  is_deeply(catalog($dbh_a), $target, "$label: the one database now reads like the other");
  return $statements;
}

# The diff between A and B is refused, and A is left as it was.
sub is_refused {
  my ($label, $sql_a, $sql_b, $expect) = @_;
  start_over();
  $dbh_a->do($_) for @$sql_a;
  $dbh_b->do($_) for @$sql_b;
  my $before = catalog($dbh_a);
  throws_ok {
    DBIO::PostgreSQL::Diff->new(source => $before, target => catalog($dbh_b))->operations
  } $expect, "$label is refused";
  return $@;
}

my @T = ('CREATE TABLE public.t (id integer PRIMARY KEY, a integer, name text)');
my @FN = (q{CREATE FUNCTION public.t96_ins() RETURNS trigger LANGUAGE plpgsql AS 'BEGIN RETURN NEW; END'});
my $trigger = sub {
  my ($name, $view) = @_;
  return "CREATE TRIGGER $name INSTEAD OF INSERT ON public.$view FOR EACH ROW EXECUTE FUNCTION public.t96_ins()";
};

# Views, a materialized view with its index, a trigger on a view: created.
{
  my @everything = (
    @T, @FN,
    'CREATE VIEW public.z_base AS SELECT id, a FROM public.t',
    'CREATE VIEW public.a_top (ident) AS SELECT id FROM public.z_base WHERE a > 0',
    'CREATE MATERIALIZED VIEW public.totals AS SELECT a, count(*) AS n FROM public.z_base GROUP BY a',
    'CREATE UNIQUE INDEX totals_a_idx ON public.totals (a)',
    $trigger->(a_top_ins => 'a_top'),
  );
  my $statements = becomes('views, a materialized view, its index, a view\'s trigger', [ @T, @FN ], \@everything);
  is_deeply(
    [ map { /\A(CREATE (?:UNIQUE )?(?:MATERIALIZED )?\w+ \S+)/ ? $1 : $_ } @$statements ],
    [
      'CREATE VIEW public.z_base',
      'CREATE VIEW public.a_top',
      'CREATE MATERIALIZED VIEW public.totals',
      'CREATE UNIQUE INDEX totals_a_idx',
      'CREATE TRIGGER a_top_ins',
    ],
    'each as what it is, in the order of what stands on what');
  is_deeply([ map { relkind($dbh_a, $_) } qw( z_base a_top totals ) ], [qw( v v m )],
    'views are views, the materialized view is one');

  # ... and dropped again, all of it.
  $statements = becomes('all of that going', \@everything, [ @T, @FN ]);
  is_deeply($statements, [
    'DROP TRIGGER a_top_ins ON public.a_top;',
    'DROP MATERIALIZED VIEW public.totals;',
    'DROP VIEW public.a_top;',
    'DROP VIEW public.z_base;',
  ], 'the trigger before its view, what reads before what is read, no DROP INDEX for the materialized view');
}

# A view that is dropped and created again keeps the trigger the target has
# on it. DROP VIEW takes the triggers; "goes" is one the target does not have.
{
  my @views = (
    'CREATE VIEW public.a_top AS SELECT id FROM public.v',
    $trigger->(stays => 'v'),
  );
  my $statements = becomes('a changed view with a trigger and a view on it',
    [ @T, @FN, 'CREATE VIEW public.v AS SELECT id, a FROM public.t', @views, $trigger->(goes => 'v') ],
    [ @T, @FN, 'CREATE VIEW public.v AS SELECT id, a FROM public.t WHERE a > 0', @views ],
  );
  is_deeply(
    [ map { /\A((?:CREATE|DROP) \w+ \S+?);?(?: |\z)/ ? $1 : $_ } @$statements ],
    [
      'DROP VIEW public.a_top', 'DROP VIEW public.v',
      'CREATE VIEW public.v', 'CREATE VIEW public.a_top',
      'CREATE TRIGGER stays',
    ],
    'the trigger is created again with its view; the one that goes gets no DROP after the view took it');
}

# A table with generated columns, created and extended.
{
  my $virtual = $version_num >= 180000;
  my @generated = (
    'gross integer GENERATED ALWAYS AS (a * 2) STORED NOT NULL',
    'lname text GENERATED ALWAYS AS (lower(name)) STORED',
    ($virtual ? 'triple integer GENERATED ALWAYS AS (a * 3) VIRTUAL' : ()),
  );
  my $with = 'CREATE TABLE public.t (id integer NOT NULL, a integer NOT NULL, name text, '
    . join(', ', @generated) . ')';
  my $without = 'CREATE TABLE public.t (id integer NOT NULL, a integer NOT NULL, name text)';

  becomes('a table with generated columns', [], [$with]);
  $dbh_a->do(q{INSERT INTO public.t (id, a, name) VALUES (1, 7, 'XY')});
  is_deeply([ $dbh_a->selectrow_array('SELECT gross, lname FROM public.t') ], [ 14, 'xy' ],
    'the columns the diff created compute');

  my $statements = becomes('generated columns added to a table', [$without], [$with]);
  is(scalar(grep { /\AALTER TABLE public\.t ADD COLUMN \w+ \w+(?: NOT NULL)? GENERATED ALWAYS AS \(.+\) (?:STORED|VIRTUAL);\z/ } @$statements),
    scalar @generated, 'each is an ADD COLUMN ... GENERATED ALWAYS AS (...)')
    or diag explain $statements;
}

# Row level security and policies of a new table.
{
  my @guarded = (
    'CREATE TABLE public.g (id integer NOT NULL, owner text)',
    'ALTER TABLE public.g ENABLE ROW LEVEL SECURITY',
    'CREATE POLICY own_rows ON public.g AS RESTRICTIVE FOR SELECT TO CURRENT_USER USING (owner = CURRENT_USER)',
    'CREATE POLICY writers ON public.g FOR INSERT TO CURRENT_USER WITH CHECK (id > 0)',
    'CREATE POLICY everybody ON public.g FOR UPDATE TO PUBLIC USING (id > 1) WITH CHECK (id > 2)',
    'CREATE POLICY plain ON public.g USING (true)',
  );
  my $statements = becomes('a table with row level security and policies', [], \@guarded);
  ok((grep { $_ eq 'ALTER TABLE public.g ENABLE ROW LEVEL SECURITY;' } @$statements),
    'row level security comes with the table');
}

# A foreign table and a partitioned table: dropped as what they are.
{
  my @fdw = (
    'CREATE FOREIGN DATA WRAPPER t96_fdw',
    'CREATE SERVER t96_srv FOREIGN DATA WRAPPER t96_fdw',
  );
  my @foreign = (@fdw, 'CREATE FOREIGN TABLE public.ft (id integer, a text) SERVER t96_srv');
  my @partitioned = (
    'CREATE TABLE public.m (d date NOT NULL, v integer) PARTITION BY RANGE (d)',
    q{CREATE TABLE public.a_part PARTITION OF public.m FOR VALUES FROM ('2025-01-01') TO ('2026-01-01')},
    q{CREATE TABLE public.m_2026 PARTITION OF public.m FOR VALUES FROM ('2026-01-01') TO ('2027-01-01')},
  );

  is_deeply(becomes('a foreign table going', \@foreign, \@fdw),
    [ 'DROP FOREIGN TABLE public.ft;' ], 'DROP FOREIGN TABLE');
  is_deeply(becomes('a partitioned table going', \@partitioned, []),
    [ 'DROP TABLE public.m;' ], 'one DROP TABLE for the table and its partitions');
  is_deeply(becomes('one partition going', \@partitioned, [ @partitioned[0, 2] ]),
    [ 'DROP TABLE public.a_part;' ], 'a partition alone is dropped for itself');
  is(catalog($dbh_b)->{tables}{'public.m_2026'}{partition_of}, 'public.m',
    'the model has from the catalog which table a partition belongs to');

  # ... and not created: the model does not hold what makes them what they are.
  is_refused('a foreign table to create', \@fdw, \@foreign,
    qr/\Arefusing to diff: foreign table public\.ft is in the target and not in the database/);
  is(relkind($dbh_a, 'ft'), undef, 'no table of that name was made');
  is_refused('a partitioned table to create', [], \@partitioned,
    qr/\Arefusing to diff: table public\.a_part is a partition of public\.m in the target and not in the database/);
  is_refused('a partitioned table without partitions to create', [], [ $partitioned[0] ],
    qr/\Arefusing to diff: partitioned table public\.m is in the target and not in the database/);
  is_refused('a partition to create', [ @partitioned[0, 2] ], \@partitioned,
    qr/\Arefusing to diff: table public\.a_part is a partition of public\.m /);
}

# A materialized view with another definition.
{
  my $message = is_refused('a materialized view with another definition',
    [ @T, 'CREATE MATERIALIZED VIEW public.totals AS SELECT a FROM public.t' ],
    [ @T, 'CREATE MATERIALIZED VIEW public.totals AS SELECT a, id FROM public.t' ],
    qr/\Arefusing to diff: materialized view public\.totals has another definition in the target/);
  like($message, qr/DROP MATERIALIZED VIEW public\.totals;/, 'the refusal says what the user can do');

  # ... which is what it says: once it is dropped, the diff creates it.
  $dbh_a->do('DROP MATERIALIZED VIEW public.totals');
  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
  like($diff->as_sql, qr/\ACREATE MATERIALIZED VIEW public\.totals AS /,
    'with the materialized view dropped by hand, the next diff creates it');
}

$_->disconnect for $dbh_a, $dbh_b;

done_testing;
