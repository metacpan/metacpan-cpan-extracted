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
use DBIO::PostgreSQL::Introspect;
use DBIO::PostgreSQL::PgSchema;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k120 (7): what is read of a database -- by the deploy,
# and by every other reader of the model -- does not depend on the
# search_path of the session that reads it (Introspect qualified_names, on by
# default).
#
# WHY it exists: PostgreSQL writes a name in a definition without its schema
# whenever the search_path of the asking session finds it -- in
# pg_get_triggerdef, pg_get_expr (a default, an index predicate, a policy),
# pg_get_indexdef, pg_get_functiondef, pg_get_function_identity_arguments
# and format_type alike. Deploy->diff reads two databases in two sessions:
# the one it was handed, under whatever search_path the caller has, and the
# temporary one, at the end of an install script that closes with SET
# search_path TO <pg_search_path>. Two texts for one object, and the diff
# compared them as text:
#
#  * a schema that was just installed had nothing to do in the session that
#    installed it, and in EVERY later session a DROP TRIGGER / CREATE TRIGGER
#    pair, the indexes dropped and built again, ALTER COLUMN ... TYPE and
#    DROP FUNCTION / CREATE FUNCTION -- for good, an upgrade did not end it;
#  * the statements came from the text of the temporary session and were run
#    in the caller's: ADD COLUMN s2 status, where the caller's search_path
#    has no "status".
#
# Asked the way it matters, the two postconditions of core ADR 0060: install,
# then diff -- in a session of its own, whatever its search_path -- finds
# nothing to do; upgrade, then diff, finds nothing either, and what the
# upgrade was for is in the catalog. And the caller's session is afterwards
# what it was: its search_path, its transaction.
#
# Everything happens in databases of this file's own (karr k81).

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my %ATTR = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);

sub path { ($_[0]->selectrow_array(q{SELECT pg_catalog.current_setting('search_path')}))[0] }

# The search_paths a session asks under. The first is the one a connection
# starts with; the second is where the install script leaves the session
# that ran it (pg_search_path of the first schema below); under the third
# nothing outside pg_catalog is found by name.
my @SESSIONS = (
  [ 'a new session'                        => undef ],
  [ 'a session with app first'             => q{SET search_path TO app, public} ],
  [ 'a session set to a schema of its own' => q{SET search_path TO t103_tenant} ],
  [ 'a session with an empty search_path'  => q{SELECT pg_catalog.set_config('search_path', '', false)} ],
);

my $n = 0;

# A schema whose objects are in "app", which is on the search_path only
# through pg_search_path: an enum, a trigger function, a function that takes
# the enum, a table with a column of the enum and its default, a partial
# index and an expression index that mention them, a trigger, a policy.
sub app_schema {
  my (%arg) = @_;
  my $id = ++$n;

  my $pg_schema = "T114::PgSchema::App$id";
  eval qq{ package $pg_schema; use base 'DBIO::PostgreSQL::PgSchema'; 1 } or die $@;
  $pg_schema->pg_enum(status => [qw( a b )]);
  $pg_schema->pg_function(touch => q{
    CREATE FUNCTION app.touch() RETURNS trigger AS $$ BEGIN RETURN NEW; END; $$ LANGUAGE plpgsql
  });
  $pg_schema->pg_function(label => q{
    CREATE FUNCTION app.label(s app.status) RETURNS text AS $$ BEGIN RETURN s::text; END; $$ LANGUAGE plpgsql IMMUTABLE
  });
  $pg_schema->pg_function(label_later => q{
    CREATE FUNCTION app.label_later(s app.status) RETURNS text AS $$ BEGIN RETURN s::text; END; $$ LANGUAGE plpgsql IMMUTABLE
  }) if $arg{upgraded};

  my $thing = "T114::Result::Thing$id";
  eval qq{
    package $thing;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->pg_schema('app');
    __PACKAGE__->table('thing');
    1;
  } or die $@;
  $thing->add_columns(
    id   => { data_type => 'integer', is_nullable => 0 },
    s    => { data_type => 'enum', pg_enum_type => 'app.status', default_value => 'a', is_nullable => 0 },
    name => { data_type => 'text', is_nullable => 1 },
    ( $arg{upgraded}
      ? (s2 => { data_type => 'enum', pg_enum_type => 'app.status', default_value => 'b', is_nullable => 1 })
      : () ),
  );
  $thing->set_primary_key('id');
  $thing->pg_trigger(thing_touch => { when => 'BEFORE', event => 'UPDATE', execute => 'app.touch()' });
  $thing->pg_trigger(thing_touch_later => { when => 'BEFORE', event => 'INSERT', execute => 'app.touch()' })
    if $arg{upgraded};
  $thing->pg_index(thing_active_idx => { columns => ['name'], where => q{s = 'a'} });
  $thing->pg_index(thing_label_idx  => { expression => 'app.label(s)' });
  $thing->pg_index(thing_later_idx  => { columns => ['name'], where => q{s2 = 'b'} })
    if $arg{upgraded};
  $thing->pg_rls({ enable => 1, policies => { thing_labelled => { using => q{app.label(s) <> ''} } } });

  my %results = (Thing => $thing);
  if ($arg{upgraded}) {
    my $other = "T114::Result::Other$id";
    eval qq{
      package $other;
      use base 'DBIO::Core';
      __PACKAGE__->load_components('PostgreSQL::Result');
      __PACKAGE__->pg_schema('app');
      __PACKAGE__->table('other');
      1;
    } or die $@;
    $other->add_columns(
      n => { data_type => 'integer', is_nullable => 1 },
      s => { data_type => 'enum', pg_enum_type => 'app.status', default_value => 'b', is_nullable => 1 },
    );
    $results{Other} = $other;
  }

  my $schema = "T114::AppSchema$id";
  { no strict 'refs'; @{"${schema}::ISA"} = ('DBIO::Schema') }
  $schema->load_components('PostgreSQL');
  $schema->pg_schemas(qw( public app ));
  $schema->pg_schema_class(app => $pg_schema);
  $schema->pg_search_path(qw( app public ));
  $schema->register_class($_ => $results{$_}) for sort keys %results;
  return $schema;
}

# The same in "public" and with the default pg_search_path: what a schema
# that declares no namespace at all looks like.
sub public_schema {
  my $id = ++$n;

  my $pg_schema = "T114::PgSchema::Public$id";
  eval qq{ package $pg_schema; use base 'DBIO::PostgreSQL::PgSchema'; 1 } or die $@;
  $pg_schema->pg_enum(mood => [qw( sad ok )]);
  $pg_schema->pg_function(touch => q{
    CREATE FUNCTION touch() RETURNS trigger AS $$ BEGIN RETURN NEW; END; $$ LANGUAGE plpgsql
  });
  $pg_schema->pg_function(label => q{
    CREATE FUNCTION label(m mood) RETURNS text AS $$ BEGIN RETURN m::text; END; $$ LANGUAGE plpgsql IMMUTABLE
  });

  my $thing = "T114::Result::PublicThing$id";
  eval qq{
    package $thing;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('thing');
    1;
  } or die $@;
  $thing->add_columns(
    id   => { data_type => 'integer', is_nullable => 0 },
    m    => { data_type => 'enum', pg_enum_type => 'mood', default_value => 'ok', is_nullable => 0 },
    name => { data_type => 'text', is_nullable => 1 },
  );
  $thing->set_primary_key('id');
  $thing->pg_trigger(thing_touch => { when => 'BEFORE', event => 'UPDATE', execute => 'touch()' });
  $thing->pg_index(thing_ok_idx    => { columns => ['name'], where => q{m = 'ok'} });
  $thing->pg_index(thing_label_idx => { expression => 'label(m)' });

  my $schema = "T114::PublicSchema$id";
  { no strict 'refs'; @{"${schema}::ISA"} = ('DBIO::Schema') }
  $schema->load_components('PostgreSQL');
  $schema->pg_schemas('public');
  $schema->pg_schema_class(public => $pg_schema);
  $schema->register_class(Thing => $thing);
  return $schema;
}

# A connection of $class to @db whose session has run $set.
sub session {
  my ($class, $set, @db) = @_;
  my $schema = $class->connect(@db, @CONNECT);
  $schema->storage->dbh->do($set) if defined $set;
  return $schema;
}

# The diff of $class against @db, asked in every session of @SESSIONS: it is
# built, finds nothing to do, and leaves the session its search_path.
sub nothing_left_in_any_session {
  my ($label, $class, @db) = @_;
  for my $session (@SESSIONS) {
    my ($where, $set) = @$session;
    my $schema = session($class, $set, @db);
    my $dbh = $schema->storage->dbh;
    my $before = path($dbh);
    my $diff = eval { $schema->pg_deploy->diff };
    ok($diff, "$label, asked in $where: the diff is built") or diag $@;
    ok($diff && !$diff->has_changes, "$label, asked in $where: nothing to do")
      or diag($diff ? $diff->as_sql : '');
    is(path($dbh), $before, "$label, asked in $where: the session keeps its search_path");
    $schema->storage->disconnect;
  }
}

{
  my $h = LiveServer->control_dbh(attrs => {%ATTR});
  note 'server ' . $h->selectrow_array('SHOW server_version');
  $h->disconnect;
}

# ---------------------------------------------------------------------------
# 1. Install, then diff -- in the session that installed, and in any other
# ---------------------------------------------------------------------------
my @app_db = PrivatePgDatabase->create('t103app');
{
  my $class = app_schema();
  my $schema = session($class, undef, @app_db);
  my $dbh = $schema->storage->dbh;
  my $before = path($dbh);
  lives_ok { $schema->pg_deploy->install } 'a schema in "app": install runs through';
  note "the installing session: search_path was [$before], is [" . path($dbh) . ']';

  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff && !$diff->has_changes, 'a schema in "app": nothing to do in the session that installed it')
    or diag($diff ? $diff->as_sql : $@);
  $schema->storage->disconnect;

  nothing_left_in_any_session('a schema in "app"', $class, @app_db);
}

my @public_db = PrivatePgDatabase->create('t103pub');
{
  my $class = public_schema();
  my $schema = session($class, undef, @public_db);
  lives_ok { $schema->pg_deploy->install } 'a schema in "public": install runs through';
  $schema->storage->disconnect;

  nothing_left_in_any_session('a schema in "public"', $class, @public_db);
}

# ---------------------------------------------------------------------------
# 2. Upgrade in a session that never ran the install script, then diff
# ---------------------------------------------------------------------------
{
  my $class = app_schema(upgraded => 1);
  my $schema = session($class, undef, @app_db);
  my $dbh = $schema->storage->dbh;
  my $before = path($dbh);

  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff && $diff->has_changes, 'the upgrade: there is something to do') or diag $@;
  my $sql = $diff ? $diff->as_sql : '';
  ok(eval { $schema->pg_deploy->apply($diff); 1 }, 'the upgrade: its statements run in the session that asked')
    or diag "$@\n$sql";
  is(path($dbh), $before, 'the upgrade: the session keeps its search_path');

  # What it was for, by oid: no name here is resolved through a search_path.
  my $facts = $dbh->selectall_arrayref(q{
    SELECT 'column ' || a.attname || ' ' || tn.nspname || '.' || t.typname
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_type t ON t.oid = a.atttypid
    JOIN pg_catalog.pg_namespace tn ON tn.oid = t.typnamespace
    WHERE n.nspname = 'app' AND (c.relname, a.attname) IN (('thing', 's2'), ('other', 's'))
    UNION ALL
    SELECT 'trigger ' || tg.tgname || ' ' || pn.nspname || '.' || p.proname
    FROM pg_catalog.pg_trigger tg
    JOIN pg_catalog.pg_proc p ON p.oid = tg.tgfoid
    JOIN pg_catalog.pg_namespace pn ON pn.oid = p.pronamespace
    WHERE tg.tgname = 'thing_touch_later'
    UNION ALL
    SELECT 'function ' || pn.nspname || '.' || p.proname
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace pn ON pn.oid = p.pronamespace
    WHERE p.proname = 'label_later'
    UNION ALL
    SELECT 'index ' || c.relname
    FROM pg_catalog.pg_class c
    WHERE c.relname = 'thing_later_idx'
    ORDER BY 1
  });
  is_deeply(
    [ map { $_->[0] } @$facts ],
    [
      'column s app.status',
      'column s2 app.status',
      'function app.label_later',
      'index thing_later_idx',
      'trigger thing_touch_later app.touch',
    ],
    'the upgrade: the column, the table, the function, the index and the trigger are in the catalog',
  ) or diag $sql;
  $schema->storage->disconnect;

  nothing_left_in_any_session('the upgraded schema', $class, @app_db);
}

# ---------------------------------------------------------------------------
# 3. The model with qualified_names: one text, whoever asks
# ---------------------------------------------------------------------------
sub model_in {
  my ($set, $db, %arg) = @_;
  my $dbh = LiveServer->control_dbh(login => $db, attrs => {%ATTR});
  $dbh->do($set) if defined $set;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh, %arg)->model;
  $dbh->disconnect;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

{
  my $first = model_in(undef, \@app_db, qualified_names => 1);
  for my $session (@SESSIONS[ 1 .. $#SESSIONS ]) {
    my ($where, $set) = @$session;
    is_deeply(model_in($set, \@app_db, qualified_names => 1), $first,
      "qualified_names: $where reads the model a new session reads");
  }

  my ($s) = grep { $_->{column_name} eq 's' } @{ $first->{columns}{'app.thing'} };
  is($s->{data_type}, 'app.status', 'qualified_names: a column type comes with its schema');
  is($s->{default_value}, q{'a'::app.status}, 'qualified_names: so does the type in a default');
  like($first->{triggers}{'app.thing'}{thing_touch}{definition},
    qr/EXECUTE FUNCTION app\.touch\(\)\z/, 'qualified_names: the function of a trigger');
  like($first->{indexes}{'app.thing'}{thing_label_idx}{definition},
    qr/\(app\.label\(s\)\)\z/, 'qualified_names: the function in an index expression');
  is($first->{indexes}{'app.thing'}{thing_active_idx}{predicate}, q{(s = 'a'::app.status)},
    'qualified_names: the type in an index predicate');
  is($first->{policies}{'app.thing'}{thing_labelled}{using_expr}, q{(app.label(s) <> ''::text)},
    'qualified_names: the function in a policy');
  ok($first->{functions}{'app.label(s app.status)'},
    'qualified_names: a function is filed under its arguments with their schema')
    or diag join ', ', sort keys %{ $first->{functions} };

  # "public" is on the search_path a connection starts with, and is written
  # all the same.
  my $public = model_in(undef, \@public_db, qualified_names => 1);
  my ($m) = grep { $_->{column_name} eq 'm' } @{ $public->{columns}{'public.thing'} };
  is($m->{data_type}, 'public.mood', 'qualified_names: a type in "public" is written public.mood');
  like($public->{triggers}{'public.thing'}{thing_touch}{definition},
    qr/EXECUTE FUNCTION public\.touch\(\)\z/, 'qualified_names: and a function there public.touch()');

  # Switched off, the model is what it was before: the names as the
  # session's search_path finds them. The default is the pinned one, for
  # every caller, DBIO::Generate among them.
  is_deeply(model_in(undef, \@public_db), $public, 'qualified_names is on by default');
  my $plain = model_in(undef, \@public_db, qualified_names => 0);
  ($m) = grep { $_->{column_name} eq 'm' } @{ $plain->{columns}{'public.thing'} };
  is($m->{data_type}, 'mood', 'without qualified_names: a type the session finds is written without schema');
  like($plain->{triggers}{'public.thing'}{thing_touch}{definition},
    qr/EXECUTE FUNCTION touch\(\)\z/, 'without qualified_names: so is the function of a trigger');
  like($plain->{tables}{'public.thing'}{kind}, qr/\Ar\z/, 'without qualified_names: the model is read all the same');
}

# ---------------------------------------------------------------------------
# 4. What reading the model leaves of the caller's session
# ---------------------------------------------------------------------------
my $START = do {
  my $h = LiveServer->control_dbh(login => [@app_db], attrs => {%ATTR});
  my $p = path($h);
  $h->disconnect;
  $p;
};

sub handle {
  my $dbh = LiveServer->control_dbh(login => [@app_db], attrs => {%ATTR, @_});
  $dbh->do('SET client_min_messages = warning');
  $dbh->commit unless $dbh->{AutoCommit};
  return $dbh;
}
sub has_table { $_[0]->selectrow_array(q{SELECT pg_catalog.to_regclass('app.t103_mine') IS NOT NULL}) ? 1 : 0 }

# ... and when the reading dies half way.
SKIP: {
  ok(DBIO::PostgreSQL::Introspect->can('under_empty_search_path'),
    'DBIO::PostgreSQL::Introspect says once how a model is read under an empty search_path')
    or skip 'no under_empty_search_path', 18;

  my $fails = sub {
    my ($dbh) = @_;
    return DBIO::PostgreSQL::Introspect->under_empty_search_path($dbh, sub {
      is(path($dbh), '', 'inside, the search_path is empty');
      $dbh->do('SELECT 1/0');
    });
  };

  {
    my $dbh = handle();
    $dbh->do('SET search_path TO app');
    throws_ok { $fails->($dbh) } qr/division by zero/, 'a query that dies, no transaction: its error is the one reported';
    is(path($dbh), 'app', 'a query that dies, no transaction: the session keeps its search_path');
    ok($dbh->{AutoCommit}, 'a query that dies, no transaction: and is in none afterwards');
    is($dbh->ping, 1, 'a query that dies, no transaction: nor is the server');
    $dbh->disconnect;
  }

  {
    my $dbh = handle();
    $dbh->begin_work;
    $dbh->do('SET LOCAL search_path TO app');
    $dbh->do('CREATE TABLE app.t103_mine (id integer)');
    throws_ok { $fails->($dbh) } qr/division by zero/, 'a query that dies, in a transaction: its error is the one reported';
    is(eval { path($dbh) }, 'app', 'a query that dies, in a transaction: the transaction goes on, under its search_path')
      or diag $@;
    ok(eval { has_table($dbh) }, 'a query that dies, in a transaction: with what it did');
    lives_ok { $dbh->commit } 'a query that dies, in a transaction: and commits';
    is(path($dbh), $START, 'a query that dies, in a transaction: after COMMIT the search_path is the session\'s');
    ok(has_table($dbh), 'a query that dies, in a transaction: and the table is there');
    $dbh->do('DROP TABLE app.t103_mine');
    $dbh->disconnect;
  }

  {
    # The whole run of a model, one section of it dying.
    my $dbh = handle();
    $dbh->do('SET search_path TO app');
    no warnings 'redefine';
    local *DBIO::PostgreSQL::Introspect::Triggers::fetch = sub { $_[1]->do('SELECT 1/0') };
    throws_ok { DBIO::PostgreSQL::Introspect->new(dbh => $dbh, qualified_names => 1)->model }
      qr/division by zero/, 'a section that dies: its error is the one reported';
    is(path($dbh), 'app', 'a section that dies: the session keeps its search_path');
    is($dbh->ping, 1, 'a section that dies: and is in no transaction');
    $dbh->disconnect;
  }

  {
    # The rule is applied once for a run, not once for each query of it: the
    # view definitions, which are read under it in every model, find it in
    # place.
    my $dbh = handle();
    my @set;
    $dbh->{Callbacks} = { do => sub { push @set, $_[1] if $_[1] =~ /set_config|SAVEPOINT/i; return } };
    DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
    is(scalar @set, 1, 'the model: the search_path is set once for the whole run')
      or diag explain \@set;
    @set = ();
    DBIO::PostgreSQL::Introspect->under_empty_search_path($dbh, sub {
      DBIO::PostgreSQL::Introspect->under_empty_search_path($dbh, sub { 1 });
    });
    is(scalar @set, 1, 'a call inside a call sets nothing up again') or diag explain \@set;
    $dbh->disconnect;
  }
}

# ---------------------------------------------------------------------------
# 5. An extension that is installed in a schema of its own
# ---------------------------------------------------------------------------
# pg_extensions names no schema. With every name read with its schema, a
# temporary database that put the extension in "public" had a column of its
# type as public.citext where the database has ext.citext, and the diff
# answered with ALTER COLUMN ... TYPE public.citext, which the database does
# not have. Decided (karr k144): the temporary database creates an extension
# that is declared without a schema, and that no control file fixes one for,
# in the schema the database holds it in. So the diff has nothing to do.
SKIP: {
  my @db = PrivatePgDatabase->create('t103ext');
  my $dbh = LiveServer->control_dbh(login => [@db], attrs => {%ATTR});
  $dbh->do('SET client_min_messages = warning');
  my ($available) = $dbh->selectrow_array(
    q{SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'citext'});
  skip 'citext is not available on this server', 2 unless $available;
  $dbh->do('CREATE SCHEMA ext');
  $dbh->do('CREATE EXTENSION citext WITH SCHEMA ext');

  my $id = ++$n;
  my $note = "T114::Result::Note$id";
  eval qq{
    package $note;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('note');
    1;
  } or die $@;
  $note->add_columns(
    id   => { data_type => 'integer', is_nullable => 0 },
    body => { data_type => 'citext', is_nullable => 1 },
  );
  $note->set_primary_key('id');
  my $class = "T114::ExtSchema$id";
  { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Schema') }
  $class->load_components('PostgreSQL');
  $class->pg_schemas('public');
  $class->pg_extensions('citext');
  $class->register_class(Note => $note);

  my $with_ext = q{SET search_path TO public, ext};
  my $schema = session($class, $with_ext, @db);
  lives_ok { $schema->pg_deploy->install } 'an extension in a schema of its own: install runs through';
  $schema->storage->disconnect;

  $schema = session($class, $with_ext, @db);
  my $diff = eval { $schema->pg_deploy->diff };
  my $sql = $diff ? $diff->as_sql : $@;
  ok($diff && !$diff->has_changes,
    'an extension in a schema of its own: the temporary database holds it there too, nothing to do')
    or diag $sql;
  $schema->storage->disconnect;
  $dbh->disconnect;
}

done_testing;
