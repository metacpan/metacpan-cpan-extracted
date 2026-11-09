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
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k120 (2, 3): the end of the install script, on a server
# and through the deploy.
#
# WHY it exists: t/102-ddl-install-script.t pins what the script looks like.
# Whether a piece of it is a statement, and whether the deploy has run it,
# only a database says afterwards -- and none of these ever said so:
#
#  * a foreign key the script skips took the statement behind it along: the
#    install ran through and the next foreign key was not there;
#  * a schema with pg_settings did not install at all (database "current"
#    does not exist);
#  * a view on a view whose source name sorts first did not install either
#    (relation does not exist), deploy_depends_on or not, and a view without
#    a pg_schema was created in the first schema of pg_search_path, away
#    from the tables it was declared next to.
#
# Asked the way it matters: the foreign key is in the catalog, a NEW session
# has the setting, the view is in the schema of its tables -- and the diff of
# what was just installed finds nothing to do.
#
# Everything happens in databases of this file's own (karr k81). ALTER
# DATABASE ... SET is run against those and nothing else.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my %ATTR = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);

my $n = 0;
sub table_class {
  my ($name, %more) = @_;
  my $class = 'T102L::Result::T' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(
    id => { data_type => 'integer', is_nullable => 0 },
    a  => { data_type => 'integer', is_nullable => 1 },
    %{ $more{columns} // {} },
  );
  $class->set_primary_key('id');
  return $class;
}
sub view_class {
  my ($name, $definition, @depends_on) = @_;
  my $class = 'T102L::Result::V' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(id => { data_type => 'integer', is_nullable => 1 });
  $class->result_source_instance->view_definition($definition);
  $class->result_source_instance->deploy_depends_on([@depends_on]) if @depends_on;
  return $class;
}
sub schema_class {
  my (%results) = @_;
  my $class = 'T102L::Schema' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->register_class($_ => $results{$_}) for sort keys %results;
  return $class;
}

# Installs $class into a database of its own. Returns the connect info of
# that database, or nothing when the install died.
sub installed {
  my ($label, $class, $tag) = @_;
  my @db = PrivatePgDatabase->create($tag);
  my $schema = $class->connect(@db, @CONNECT);
  my $ok = ok(eval { $schema->pg_deploy->install; 1 }, "$label: install runs through")
    or diag "$@\n" . $schema->pg_install_ddl;
  $schema->storage->disconnect;
  return $ok ? @db : ();
}

# The diff of what was installed, asked in a session of its own.
sub nothing_left {
  my ($label, $class, @db) = @_;
  my $schema = $class->connect(@db, @CONNECT);
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, "$label: the diff of what was installed is built") or diag $@;
  ok($diff && !$diff->has_changes, "$label: and finds nothing to do")
    or diag($diff ? $diff->as_sql : '');
  $schema->storage->disconnect;
}

# schema.name(kind) of every table and view outside the system schemas.
sub relations {
  my ($dbh) = @_;
  return [ map { "$_->[0].$_->[1]($_->[2])" } @{ $dbh->selectall_arrayref(q{
    SELECT n.nspname, c.relname, c.relkind
    FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast') AND c.relkind IN ('r', 'v')
    ORDER BY 1, 2}) } ];
}

sub foreign_keys {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref(
    q{SELECT conname FROM pg_catalog.pg_constraint WHERE contype = 'f' ORDER BY 1});
}

my $superuser;
{
  my $h = LiveServer->control_dbh(attrs => {%ATTR});
  note 'server ' . $h->selectrow_array('SHOW server_version');
  ($superuser) = $h->selectrow_array(
    'SELECT rolsuper FROM pg_catalog.pg_roles WHERE rolname = current_user');
  $h->disconnect;
}

# ---------------------------------------------------------------------------
# 1. A foreign key the script skips, and what stands behind it
# ---------------------------------------------------------------------------
{
  my $customer = table_class('customer');
  my %fk = (columns => { customer_id => { data_type => 'integer', is_nullable => 1 } });

  # By source name: A is skipped, B has a foreign key, D has one -- and
  # behind them come the views. A foreign class that is not loaded and a
  # table outside the deploy are not skipped but refused (t/102-ddl-install-
  # script.t; karr k120).
  my $a = table_class('a_weird', %fk);
  $a->belongs_to(customer => $customer, sub { {} });
  my $b = table_class('b_order', %fk);
  $b->belongs_to(customer => $customer, 'customer_id');
  my $d = table_class('d_order', %fk);
  $d->belongs_to(customer => $customer, 'customer_id');
  $_->pg_fk_constraints_from_rels(1) for $a, $b, $d;

  my $schema = schema_class(A => $a, B => $b, D => $d, Customer => $customer,
    V => view_class(behind_the_keys => 'SELECT id FROM customer'));
  is(scalar(() = $schema->pg_install_ddl =~ /^-- skipped FK /mg), 1,
    'precondition: the script skips one foreign key');

  SKIP: {
    my @db = installed('a skipped foreign key among two that are written', $schema, 't102fk')
      or skip 'the install failed', 4;
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
    is_deeply(foreign_keys($dbh), [qw( b_order_customer_id_fkey d_order_customer_id_fkey )],
      'the foreign key behind the skipped one is in the database');
    is((grep { $_ eq 'public.behind_the_keys(v)' } @{ relations($dbh) }), 1,
      'and so is the view behind them');
    $dbh->disconnect;
    nothing_left('skipped foreign keys', $schema, @db);
  }
}

# ---------------------------------------------------------------------------
# 2. pg_settings
# ---------------------------------------------------------------------------
{
  my %settings = (
    default_text_search_config => 'pg_catalog.german',
    statement_timeout          => '4321s',
  );
  # A parameter of the application's own takes any text, which is what shows
  # that a value arrives as written -- and it takes a superuser to set one on
  # a database.
  my %own = ('dbio_t102.greeting' => q{it's; a $dbio$ b $$ c});

  my $schema = schema_class(Item => table_class('item'));
  $schema->pg_settings({ %settings, ($superuser ? %own : ()) });
  my $changed = schema_class(Item => table_class('item'));
  $changed->pg_settings({ %settings, statement_timeout => '1234s' });

  SKIP: {
    my @db = installed('a schema with pg_settings', $schema, 't102set')
      or skip 'the install failed', 8;

    # The session that installed is gone; this one is new.
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
    is($dbh->selectrow_array('SELECT current_setting(?)', undef, $_), $settings{$_},
      "a new session of the database has $_ as declared") for sort keys %settings;
    SKIP: {
      skip 'setting a parameter of the application\'s own on a database takes a superuser', 1
        unless $superuser;
      is($dbh->selectrow_array('SELECT current_setting(?)', undef, $_), $own{$_},
        "... and $_, a value with an apostrophe, a semicolon and dollar signs, as written") for sort keys %own;
    }

    # ... of this database, and of no other: the temporary database the diff
    # deploys into gets the settings as well, and goes with them.
    my $databases_with = sub {
      $dbh->selectcol_arrayref(q{
        SELECT d.datname FROM pg_catalog.pg_db_role_setting s
        JOIN pg_catalog.pg_database d ON d.oid = s.setdatabase
        WHERE s.setrole = 0 AND 'statement_timeout=4321s' = ANY (s.setconfig)
        ORDER BY 1});
    };
    my ($name) = $dbh->selectrow_array('SELECT current_database()');
    is_deeply($databases_with->(), [$name], 'the setting is on the database installed into and on no other');

    nothing_left('pg_settings', $schema, @db);
    is_deeply($databases_with->(), [$name], 'the diff has left the setting on no other database either');

    # INSTALL ONLY, as the POD of pg_settings says: the model the diff
    # compares does not hold the settings of a database, so a value that
    # changes in the declaration is not followed by an upgrade. Held here so
    # that the day it is, this is the place that says what has to change.
    my $later = $changed->connect(@db, @CONNECT);
    my $diff = $later->pg_deploy->diff;
    ok(!$diff->has_changes, 'install only: a changed value in the declaration is no change for the diff')
      or diag $diff->as_sql;
    $later->storage->disconnect;
    $dbh->disconnect;
  }
}

# ---------------------------------------------------------------------------
# 3. Views: in the order of what they read, next to the tables
# ---------------------------------------------------------------------------
{
  # By source name and by its own name the view that reads comes first.
  my $item = table_class('item');
  my $base = view_class(z_base => 'SELECT id, a FROM item');
  my $top  = view_class(a_top  => 'SELECT id FROM z_base WHERE a > 0', $base);
  my $schema = schema_class(ATop => $top, Item => $item, ZBase => $base);

  SKIP: {
    my @db = installed('a view on a view whose names sort the other way', $schema, 't102view')
      or skip 'the install failed', 4;
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
    is_deeply(relations($dbh), [qw( public.a_top(v) public.item(r) public.z_base(v) )],
      'both views are in the database');
    $dbh->do('INSERT INTO item (id, a) VALUES (1, -1), (2, 2)');
    is_deeply($dbh->selectcol_arrayref('SELECT id FROM a_top'), [2], 'and the one reads through the other');
    $dbh->disconnect;
    nothing_left('a view on a view', $schema, @db);
  }

  my $one = view_class(v_one => 'SELECT id FROM v_two');
  my $two = view_class(v_two => 'SELECT id FROM v_one');
  $one->result_source_instance->deploy_depends_on([$two]);
  $two->result_source_instance->deploy_depends_on([$one]);
  my $circle = schema_class(Item => $item, One => $one, Two => $two);
  my @db = PrivatePgDatabase->create('t102circle');
  my $connected = $circle->connect(@db, @CONNECT);
  throws_ok { $connected->pg_deploy->install }
    qr/\Arefusing to write the install DDL: .*\bview v_one\b.*\bview v_two\b/s,
    'views that name one another are refused by install, with their names';
  is_deeply(relations($connected->storage->dbh), [], 'and nothing was created');
  $connected->storage->disconnect;
}

{
  # No pg_schema on the table and none on the view: the table is created
  # where the session puts it, and the view has to be there as well -- not
  # in the first schema of the declared search_path, which the script sets
  # for what comes after it.
  my $schema = schema_class(
    Item     => table_class('item'),
    Positive => view_class(positive => 'SELECT id, a FROM item WHERE a > 0'));
  $schema->pg_schemas(qw( public app ));
  $schema->pg_search_path(qw( app public ));

  SKIP: {
    my @db = installed('a view without pg_schema under a declared search_path', $schema, 't102path')
      or skip 'the install failed', 3;
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
    # The claim -- the view lies next to its table -- stands. Where both lie
    # changed with karr k121 (point 4): the declared pg_search_path is the
    # path of the connection that installs, so both are created in its first
    # existing schema, app, and not in public; the script itself still sets
    # no path.
    is_deeply(relations($dbh), [qw( app.item(r) app.positive(v) )],
      'the view lies next to the table it was declared next to, in the first schema of the declared path');
    $dbh->disconnect;
    nothing_left('a view without pg_schema', $schema, @db);
  }
}

# ---------------------------------------------------------------------------
# 4. The script as one piece
# ---------------------------------------------------------------------------
{
  # What the deploy cuts apart, psql -f and a single do() read as it stands:
  # notes, a statement that closes with a comment, the settings, the views.
  {
    package T102L::PgSchema::Public;
    use base 'DBIO::PostgreSQL::PgSchema';
    __PACKAGE__->pg_function('t102_touch' => q{
      CREATE FUNCTION t102_touch() RETURNS trigger AS $$ BEGIN RETURN NEW; END; $$ LANGUAGE plpgsql -- for the triggers
    });
  }
  my $customer = table_class('customer');
  $customer->pg_extra_ddl(
    'CREATE INDEX customer_tail_idx ON customer (a) -- a note behind it',
    'CREATE INDEX customer_plain_idx ON customer (a, id);',
  );
  my $weird = table_class('weird', columns => { customer_id => { data_type => 'integer', is_nullable => 1 } });
  $weird->belongs_to(customer => $customer, sub { {} });
  $weird->pg_fk_constraints_from_rels(1);
  my $schema = schema_class(Customer => $customer, Weird => $weird,
    Noted => view_class(v_noted => 'SELECT id FROM customer -- every one of them'),
    Plain => view_class(v_plain => 'SELECT id FROM v_noted'));
  $schema->pg_schemas('public');
  $schema->pg_schema_class(public => 'T102L::PgSchema::Public');
  $schema->pg_settings({ statement_timeout => '4321s' });

  my @db = PrivatePgDatabase->create('t102whole');
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
  my $script = $schema->pg_install_ddl;
  ok(eval { $dbh->do($script); 1 }, 'the script runs as one piece') or diag "$@\n$script";
  is_deeply(relations($dbh), [qw( public.customer(r) public.v_noted(v) public.v_plain(v) public.weird(r) )],
    'every table and view of it is in the database');
  is_deeply(
    $dbh->selectcol_arrayref(q{SELECT indexname FROM pg_catalog.pg_indexes
      WHERE schemaname = 'public' AND indexname LIKE 'customer\_%\_idx' ORDER BY 1}),
    [qw( customer_plain_idx customer_tail_idx )],
    'and the index behind a statement that closes with a comment');
  $dbh->disconnect;

  # ... and through the deploy the same. A deploy that reads comments (core
  # k326) takes "-- a note;" for a comment to the end of its line, as the
  # server does: with the semicolon behind it the two indexes were one
  # statement, which the server refuses.
  my $made = sub {
    my ($label, @db) = @_;
    my $h = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
    is_deeply(relations($h), [qw( public.customer(r) public.v_noted(v) public.v_plain(v) public.weird(r) )],
      "$label: every table and view is in the database");
    is_deeply(
      $h->selectcol_arrayref(q{SELECT indexname FROM pg_catalog.pg_indexes
        WHERE schemaname = 'public' AND indexname LIKE 'customer\_%\_idx' ORDER BY 1}),
      [qw( customer_plain_idx customer_tail_idx )],
      "$label: the statement that closes with a comment has run, and the one behind it");
    is($h->selectrow_array('SHOW statement_timeout'), '4321s',
      "$label: and the setting behind the note of the skipped foreign key");
    $h->disconnect;
  };
  SKIP: {
    my @deployed = installed('the same schema', $schema, 't102same')
      or skip 'the install failed', 5;
    $made->('through the deploy', @deployed);
    nothing_left('the same schema', $schema, @deployed);
  }

  # ... and through deploy_async on the future_io transport, which cuts the
  # same script with the same splitter and sends each statement for itself.
  SKIP: {
    eval {
      require IO::Async::Loop;
      require Future::IO::Impl::IOAsync;
      Future::IO::Impl::IOAsync->import;
      require DBIO::PostgreSQL::Storage::Async;
      1;
    } or skip 'Future::IO::Impl::IOAsync, IO::Async and DBIO::Async are needed for deploy_async', 4;

    my @async_db = PrivatePgDatabase->create('t102async');
    my $async_schema = $schema->connect(@async_db, { async => 'future_io', PrintError => 0, PrintWarn => 0 });
    ok(eval { $async_schema->storage->async->deploy_async($async_schema)->get; 1 },
      'deploy_async runs through') or diag $@;
    $async_schema->storage->disconnect;
    $made->('through deploy_async', @async_db);
  }
}

done_testing;
