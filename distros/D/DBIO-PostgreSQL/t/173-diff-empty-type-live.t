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

LiveServer->require_server;

# LIVE test for karr k121: an enum without values or a composite type without
# attributes was never in the model (the join on pg_enum / pg_attribute gave
# no row). A target that declares such a type empty, where the database has
# it with values or attributes, was read as "the target does not declare the
# type": DROP TYPE ... CASCADE, and every column of the type went with it.
#
# The claim: such a diff is refused by name, and the type and the rows are
# as they were. A type the target does not declare at all stays a plain drop.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t173a t173b );

sub catalog {
  my ($dbh) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

sub start_over {
  my ($sql_a, $sql_b) = @_;
  for my $dbh ($dbh_a, $dbh_b) {
    $dbh->do($_) for 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
  }
  $dbh_a->do($_) for @$sql_a;
  $dbh_b->do($_) for @$sql_b;
}

sub ops {
  return DBIO::PostgreSQL::Diff->new(
    source => catalog($dbh_a), target => catalog($dbh_b))->operations;
}

my @cases = (
  [ enum => q{CREATE TYPE public.t AS ENUM ('a', 'b')}, q{CREATE TYPE public.t AS ENUM ()},
    q{INSERT INTO public.u VALUES (1, 'a'), (2, 'b')}, 'values' ],
  [ composite => q{CREATE TYPE public.t AS (x integer, y text)}, q{CREATE TYPE public.t AS ()},
    q{INSERT INTO public.u VALUES (1, ROW(1, 'a')), (2, ROW(2, 'b'))}, 'attributes' ],
);

for my $case (@cases) {
  my ($kind, $full, $empty, $insert, $what) = @$case;
  start_over(
    [ $full, q{CREATE TABLE public.u (id integer PRIMARY KEY, c public.t)}, $insert ],
    [ $empty, q{CREATE TABLE public.u (id integer PRIMARY KEY)} ],
  );
  ok exists catalog($dbh_b)->{types}{'public.t'}, "$kind: the empty type is in the target model";
  my @ops = eval { @{ ops() } };
  my $err = $@;
  like $err, qr/\Arefusing to diff: $kind type public\.t is declared empty in the target but has $what in the database\n/,
    "$kind: declared empty in the target, with $what in the database, is refused";
  like $err, qr/No statement was generated\./, '... and no statement was written';
  is scalar @ops, 0, '... and no operation built';
  is $dbh_a->selectrow_array(q{SELECT count(*) FROM public.u}), 2, '... the rows are still there';
  is $dbh_a->selectrow_array(q{SELECT count(*) FROM pg_attribute WHERE attrelid = 'public.u'::regclass AND attname = 'c' AND NOT attisdropped}),
    1, '... and so is the column of the type';
}

# A type the target does not declare at all is a plain drop, as before.
start_over(
  [ q{CREATE TYPE public.t AS ENUM ('a', 'b')} ],
  [],
);
my @sql = eval { map { $_->as_sql } @{ ops() } };
is_deeply \@sql, [ q{DROP TYPE public.t;} ],
  'a type the target does not declare: DROP TYPE, not refused' or diag $@;

# Empty on both sides: no operation. Empty in the database, values in the
# target: the values are added.
start_over(
  [ q{CREATE TYPE public.t AS ENUM ()} ],
  [ q{CREATE TYPE public.t AS ENUM ()} ],
);
is scalar @{ ops() }, 0, 'empty on both sides is no operation';

start_over(
  [ q{CREATE TYPE public.t AS ENUM ()} ],
  [ q{CREATE TYPE public.t AS ENUM ('a', 'b')} ],
);
@sql = map { $_->as_sql } @{ ops() };
ok eval { $dbh_a->do($_) for map { split /\n/ } @sql; 1 },
  'an empty enum in the database gets the target values: the server takes it' or diag $@;
is scalar @{ ops() }, 0, '... and afterwards the diff is empty';

done_testing;
