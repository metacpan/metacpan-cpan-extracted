use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k152: a drop stops at the edge of the model.
#
# DROP TABLE, DROP TYPE and DROP SCHEMA were written with CASCADE. A deploy
# restricted by pg_schemas reads the declared schemas only, so a materialized
# view of another schema that reads the table, the foreign key of another
# schema's table that points at it, or the column of another schema's table
# that is of the type went with the drop -- with its data, and unseen.
#
# With database A as what there is and B as what is wanted (both read through
# the schema filter [app], as a deploy with pg_schemas('app') reads them):
#
#  1. the table is not declared any more while a materialized view, a foreign
#     key, a partition or an inheriting table of another schema stands on it:
#     the diff is refused, naming each; the same for an enum that a column,
#     a function or a domain of another schema is built on;
#  2. without such an object the drops run, and afterwards the diff is empty;
#  3. what the diff can not see -- a policy of another schema's table that
#     reads the table in its USING clause -- stops the DROP TABLE at the
#     server (RESTRICT), and the transaction leaves the database as it was;
#  4. what the model holds goes first: tables that reference each other, an
#     inheriting table and its parent, a composite type over an enum, a schema
#     with its table, type, function and a sequence no column owns -- and the
#     statements run;
#  5. an unfiltered diff that drops a schema holding what the model does not
#     (a domain) is refused naming it.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t194a t194b );

my @schemas = qw( app reports other old );

sub catalog {
  my ($dbh, $filter) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(
    dbh => $dbh, ($filter ? (schema_filter => $filter) : ()))->model;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

sub start_over {
  my ($sql_a, $sql_b) = @_;
  for my $dbh ($dbh_a, $dbh_b) {
    $dbh->do($_) for
      (map { "DROP SCHEMA IF EXISTS $_ CASCADE" } @schemas), 'DROP DOMAIN IF EXISTS public.d CASCADE',
      'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public', 'CREATE SCHEMA app';
  }
  $dbh_a->do($_) for @$sql_a;
  $dbh_b->do($_) for @$sql_b;
}

# [] unfiltered, else the schemas of a deploy restricted by pg_schemas.
sub diff {
  my ($filter) = @_;
  return DBIO::PostgreSQL::Diff->new(
    source => catalog($dbh_a, $filter), target => catalog($dbh_b, $filter));
}

sub refusal {
  my ($filter) = @_;
  my $d = diff($filter);
  my $ops = eval { $d->operations };
  return ($@, $ops);
}

# The statements in one transaction, as Deploy->apply runs them.
sub apply {
  my (@sql) = @_;
  $dbh_a->begin_work;
  return 1 if eval { $dbh_a->do($_) for map { split /\n/ } @sql; $dbh_a->commit; 1 };
  my $error = $@;
  $dbh_a->rollback;
  return (0, $error);
}

sub count {
  my ($sql) = @_;
  return scalar $dbh_a->selectrow_array($sql);
}

my $APP = ['app'];

# --- 1. what stands outside is named ------------------------------------------

start_over(
  [ q{CREATE TABLE app.orders (id integer PRIMARY KEY, total integer)},
    q{INSERT INTO app.orders VALUES (1, 10), (2, 20)},
    q{CREATE SCHEMA reports}, q{CREATE SCHEMA other},
    q{CREATE MATERIALIZED VIEW reports.monthly AS SELECT total FROM app.orders},
    q{CREATE VIEW reports.plain AS SELECT id FROM app.orders},
    q{CREATE TABLE other.child (id integer PRIMARY KEY, order_id integer CONSTRAINT child_order_fkey REFERENCES app.orders (id))},
    q{CREATE TABLE app.log (id integer PRIMARY KEY)} ],
  [ q{CREATE TABLE app.log (id integer PRIMARY KEY)} ],
);
{
  my $model = catalog($dbh_a, $APP);
  is_deeply [ sort map { "$_->{kind} $_->{name}" . ($_->{on} ? " on $_->{on}" : '') } @{ $model->{outside_dependents}{tables}{'app.orders'} } ],
    [ 'foreign key child_order_fkey on other.child', 'materialized view reports.monthly', 'view reports.plain' ],
    'the model names what stands on the table outside the filter: views, materialized views, foreign keys';
  ok !exists $model->{outside_dependents}{tables}{'app.log'}, '... and nothing for a table nothing stands on';

  my ($err, $ops) = refusal($APP);
  like $err, qr/\Arefusing to diff: table app\.orders is not in the target and would be dropped, and these objects outside the deploy depend on it:\n/,
    'the table is not declared any more: the diff is refused';
  like $err, qr/^  materialized view reports\.monthly$/m, '... naming the materialized view';
  like $err, qr/^  view reports\.plain$/m, '... the view';
  like $err, qr/^  foreign key child_order_fkey on other\.child$/m, '... and the foreign key';
  unlike $err, qr/\b(?:10|20)\b/, '... and no row value';
  ok !$ops, '... with no operation built';
  is count(q{SELECT sum(total) FROM reports.monthly}), 30, '... the materialized view still holds its data';
}

# partitions and inheriting tables of another schema
start_over(
  [ q{CREATE SCHEMA other},
    q{CREATE TABLE app.pt (id integer, k integer) PARTITION BY RANGE (k)},
    q{CREATE TABLE other.pt1 PARTITION OF app.pt FOR VALUES FROM (0) TO (10)},
    q{CREATE TABLE app.base (id integer)},
    q{CREATE TABLE other.kid () INHERITS (app.base)} ],
  [],
);
{
  my ($err) = refusal($APP);
  like $err, qr/^  partition other\.pt1$/m, 'a partition of another schema is named';
  like $err, qr/^  inheriting table other\.kid$/m, '... and so is a table of another schema that inherits from it';
}

# an enum a column, a function and a domain of another schema are built on
start_over(
  [ q{CREATE SCHEMA other},
    q{CREATE TYPE app.status AS ENUM ('a', 'b')},
    q{CREATE TABLE other.t (id integer, status app.status)},
    q{CREATE TABLE other.arr (tags app.status[])},
    q{CREATE FUNCTION other.f(s app.status) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
    q{CREATE DOMAIN other.status_d AS app.status},
    q{INSERT INTO other.t VALUES (1, 'a')} ],
  [],
);
{
  my ($err, $ops) = refusal($APP);
  like $err, qr/\Arefusing to diff: enum type app\.status is not in the target and would be dropped, and these objects outside the deploy depend on it:\n/,
    'the enum is not declared any more: the diff is refused';
  like $err, qr/^  column other\.t\.status$/m, '... naming the column of the other table';
  like $err, qr/^  column other\.arr\.tags$/m, '... also where it is an array of the enum';
  like $err, qr/^  function other\.f\(app\.status\)$/m, '... the function that takes it';
  like $err, qr/^  domain other\.status_d$/m, '... and the domain over it';
  ok !$ops, '... with no operation built';
  is count(q{SELECT count(*) FROM other.t WHERE status = 'a'}), 1, '... the column and its data are still there';
}

# --- 2. nothing stands outside: the drops run as before -----------------------

start_over(
  [ q{CREATE SCHEMA other},
    q{CREATE TYPE app.status AS ENUM ('a', 'b')},
    q{CREATE TABLE app.orders (id integer PRIMARY KEY, s app.status)},
    q{CREATE TABLE other.unrelated (id integer PRIMARY KEY)} ],
  [ q{CREATE SCHEMA other} ],
);
{
  my @sql = map { $_->as_sql } @{ diff($APP)->operations };
  is_deeply \@sql, [ 'DROP TABLE app.orders;', 'DROP TYPE app.status;' ],
    'without a dependent outside the model the table and the type are dropped, without CASCADE';
  my ($ok, $error) = apply(@sql);
  ok $ok, '... and the server takes them' or diag $error;
  is count(q{SELECT count(*) FROM other.unrelated}), 0, '... what is outside is as it was';
  is scalar @{ diff($APP)->operations }, 0, '... and afterwards the diff is empty';
}

# --- 3. what the diff can not see: RESTRICT, and the transaction rolls back ---

start_over(
  [ q{CREATE SCHEMA other},
    q{CREATE TABLE app.a_first (id integer PRIMARY KEY)},
    q{CREATE TABLE app.orders (id integer PRIMARY KEY)},
    q{CREATE TABLE other.t (id integer)},
    q{ALTER TABLE other.t ENABLE ROW LEVEL SECURITY},
    q{CREATE POLICY p ON other.t USING (id IN (SELECT id FROM app.orders))} ],
  [],
);
{
  my $d = diff($APP);
  my @sql = eval { map { $_->as_sql } @{ $d->operations } };
  is_deeply \@sql, [ 'DROP TABLE app.a_first;', 'DROP TABLE app.orders;' ],
    'a policy of another schema that reads the table is not in the section: the drops are written';
  my ($ok, $error) = apply(@sql);
  ok !$ok, '... and the server refuses the second: the table is not dropped with CASCADE';
  like $error, qr/cannot drop table app\.orders because other objects depend on it/,
    '... in its own words';
  is count(q{SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname = 'app' AND c.relkind = 'r'}), 2,
    '... and the transaction left both tables where they were';
  is count(q{SELECT count(*) FROM pg_policy}), 1, '... and the policy';
}

# --- 4. what the model holds goes first ---------------------------------------

# tables that reference each other, and an inheriting table
start_over(
  [ q{CREATE TABLE app.a (id integer PRIMARY KEY, b_id integer)},
    q{CREATE TABLE app.b (id integer PRIMARY KEY, a_id integer REFERENCES app.a (id))},
    q{ALTER TABLE app.a ADD CONSTRAINT a_b_fkey FOREIGN KEY (b_id) REFERENCES app.b (id)},
    q{CREATE TABLE app.p (id integer)},
    q{CREATE TABLE app.c () INHERITS (app.p)},
    q{CREATE TABLE app.keep (id integer PRIMARY KEY)},
    q{CREATE TABLE app.holder (k integer REFERENCES app.a (id))} ],
  [ q{CREATE TABLE app.keep (id integer PRIMARY KEY)} ],
);
{
  my @sql = map { $_->as_sql } @{ diff($APP)->operations };
  is_deeply [ grep { /\ADROP TABLE/ } @sql ],
    [ 'DROP TABLE app.b;', 'DROP TABLE app.c;', 'DROP TABLE app.holder;', 'DROP TABLE app.a;', 'DROP TABLE app.p;' ],
    'the tables are dropped by name, the one that holds a key or inherits ahead of the one it points at';
  is scalar(grep { /\ADROP CONSTRAINT|\AALTER TABLE .* DROP CONSTRAINT/ } @sql), 2,
    '... and the two keys that point at each other are dropped ahead of them, the others go with their table';
  my ($ok, $error) = apply(@sql);
  ok $ok, '... and the server takes them, though two reference each other and a third references one' or diag $error;
  is scalar @{ diff($APP)->operations }, 0, '... and afterwards the diff is empty';
}

# types built on one another
start_over(
  [ q{CREATE TYPE app.mood AS ENUM ('a', 'b')},
    q{CREATE TYPE app.box AS (m app.mood[], n integer)},
    q{CREATE TYPE app.moodrange AS RANGE (subtype = text)},
    q{CREATE TYPE app.zbox AS (m app.mood)} ],
  [],
);
{
  my @sql = map { $_->as_sql } @{ diff($APP)->operations };
  is_deeply \@sql, [ 'DROP TYPE app.box;', 'DROP TYPE app.moodrange;', 'DROP TYPE app.zbox;', 'DROP TYPE app.mood;' ],
    'a type is dropped ahead of the composite types built on it';
  my ($ok, $error) = apply(@sql);
  ok $ok, '... and the server takes them' or diag $error;
}

# a whole schema, unfiltered
start_over(
  [ q{CREATE SCHEMA old},
    q{CREATE TYPE old.kind AS ENUM ('a')},
    q{CREATE SEQUENCE old.loose},
    q{CREATE TABLE old.t (id serial PRIMARY KEY, k old.kind DEFAULT 'a')},
    q{CREATE FUNCTION old.f(k old.kind) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
    q{CREATE VIEW old.v AS SELECT id FROM old.t} ],
  [],
);
{
  my @sql = map { $_->as_sql } @{ diff()->operations };
  like $sql[-1], qr/\ADROP SCHEMA old;\z/, 'the schema is dropped last, without CASCADE';
  ok scalar(grep { $_ eq 'DROP SEQUENCE old.loose;' } @sql), '... after the sequence no column owns';
  my ($ok, $error) = apply(@sql);
  ok $ok, '... and the server takes the statements: table, view, type, function, sequence, schema' or diag $error;
  is count(q{SELECT count(*) FROM pg_namespace WHERE nspname = 'old'}), 0, '... the schema is gone';
  is scalar @{ diff()->operations }, 0, '... and afterwards the diff is empty';
}

# --- 5. a schema that holds what the model does not ---------------------------

start_over(
  [ q{CREATE SCHEMA old},
    q{CREATE DOMAIN old.d AS integer},
    q{CREATE TABLE old.t (id old.d)} ],
  [],
);
{
  my ($err, $ops) = refusal();
  like $err, qr/\Arefusing to diff: schema old is not in the target and would be dropped, and these objects outside the deploy depend on it:\n/,
    'a schema with a domain is refused';
  like $err, qr/^  domain old\.d$/m, '... naming the domain';
  ok !$ops, '... with no operation built';
  is count(q{SELECT count(*) FROM pg_namespace WHERE nspname = 'old'}), 1, '... the schema is still there';
}

done_testing;
