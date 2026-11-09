use strict;
use warnings;

use Test::More;
use Test::Exception;

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

# LIVE test for karr k121 (U7, points 3 and 4): the routine kinds.
#
# WHAT it claims, with database A as what there is and B as what is wanted:
#
#  1. a function and a procedure under one signature are one key in the
#     model. The diff used to write CREATE OR REPLACE PROCEDURE over the
#     function (and the other way round) and the server answered "cannot
#     change routine kind". Now the old one is dropped ahead of the new one
#     is created, and the statements run, in both directions;
#  2. an aggregate and a window function were not in the model at all: one
#     the target has was created by no upgrade, one with another definition
#     was changed by none, and nothing said so. pg_get_functiondef raises an
#     error for them, so there is no text to write one from: the diff is
#     refused for one it would have to create or change, naming it. One
#     that is the same on both sides is no operation, and one only the
#     database has is dropped (DROP AGGREGATE; DROP FUNCTION for a window
#     function), like any function (karr k121; it was left where it was).

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t137a t137b );

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

my $function  = q{CREATE FUNCTION public.f(integer) RETURNS integer LANGUAGE sql AS 'SELECT $1'};
my $procedure = q{CREATE PROCEDURE public.f(integer) LANGUAGE sql AS 'SELECT 1'};

# --- 1. function <-> procedure ----------------------------------------------

for my $case (
  [ 'function to procedure', $function,  $procedure, 'DROP FUNCTION', 'CREATE OR REPLACE PROCEDURE' ],
  [ 'procedure to function', $procedure, $function,  'DROP PROCEDURE', 'CREATE OR REPLACE FUNCTION' ],
) {
  my ($label, $from, $to, $drop, $create) = @$case;
  start_over([ $from ], [ $to ]);

  my @sql = map { $_->as_sql } @{ ops() };
  is scalar @sql, 2, "$label: two statements";
  like $sql[0] // '', qr/\A\Q$drop\E public\.f\((?:IN )?integer\);\z/, "$label: the old one is dropped first";
  like $sql[1] // '', qr/\A\Q$create\E public\.f\((?:IN )?integer\)/,  "$label: the new one is created";

  ok eval { $dbh_a->do($_) for @sql; 1 }, "$label: the server takes them" or diag $@;
  is scalar @{ ops() }, 0, "$label: afterwards the diff is empty";
}

# --- 2. aggregates and window functions -------------------------------------

my $agg = sub {
  my ($init) = @_;
  return "CREATE AGGREGATE public.mysum(integer) (SFUNC = int4pl, STYPE = integer, INITCOND = '$init')";
};

start_over([], [ $agg->(0) ]);
throws_ok { ops() } qr/\Arefusing to diff: aggregate public\.mysum\(integer\) is in the target and not in the database/m,
  'an aggregate the database lacks is refused, by name';
like $@, qr/CREATE AGGREGATE/, '... and the message says what to do';

start_over([ $agg->(0) ], [ $agg->(5) ]);
throws_ok { ops() } qr/\Arefusing to diff: aggregate public\.mysum\(integer\) is in the database and in the target with another definition/m,
  'an aggregate with another definition is refused';

start_over([ $agg->(0) ], [ $agg->(0) ]);
is scalar @{ ops() }, 0, 'the same aggregate on both sides is no operation';

start_over([ $agg->(0) ], []);
my @drop = map { $_->as_sql } @{ ops() };
is_deeply \@drop, ['DROP AGGREGATE public.mysum(integer);'],
  'an aggregate only the database has is dropped by DROP AGGREGATE';
ok eval { $dbh_a->do($_) for @drop; 1 }, '... and the server takes it' or diag $@;
is scalar @{ ops() }, 0, '... afterwards the diff is empty';
my ($left) = $dbh_a->selectrow_array(q{SELECT count(*) FROM pg_catalog.pg_proc WHERE proname = 'mysum'});
is $left, 0, '... and the aggregate is gone';

# A window function: its body is a C or internal routine, which only a
# superuser may declare.
my ($super) = $dbh_a->selectrow_array(q{SELECT rolsuper FROM pg_catalog.pg_roles WHERE rolname = current_user});
SKIP: {
  skip 'declaring a window function needs a superuser', 5 unless $super;
  my $window = q{CREATE FUNCTION public.w() RETURNS bigint AS 'window_rank' LANGUAGE internal WINDOW};
  start_over([], [ $window ]);
  throws_ok { ops() } qr/\Arefusing to diff: window function public\.w\(\) is in the target and not in the database/m,
    'a window function the database lacks is refused, by name';
  start_over([ $window ], [ $window ]);
  is scalar @{ ops() }, 0, 'the same window function on both sides is no operation';
  start_over([ $window ], []);
  my @wdrop = map { $_->as_sql } @{ ops() };
  is_deeply \@wdrop, ['DROP FUNCTION public.w();'],
    'a window function only the database has is dropped by DROP FUNCTION';
  ok eval { $dbh_a->do($_) for @wdrop; 1 }, '... and the server takes it' or diag $@;
  is scalar @{ ops() }, 0, '... afterwards the diff is empty';
}

# --- 3. a procedure and a function the keys do not pair (karr k121) --------
#
# The server holds one routine per name and input argument types, function or
# procedure. A create of the other kind while the old one still stands is
# answered "already exists with same argument types". Keys that pair (the
# mode IN left out) are dropped and created; an INOUT argument, another name
# or an OUT argument one side has leave them unpaired, and the diff refuses
# ahead instead of letting the server do it at the apply.

for my $case (
  [ 'procedure INOUT to function',
    q{CREATE PROCEDURE public.f(INOUT x integer) LANGUAGE plpgsql AS 'BEGIN END'},
    q{CREATE FUNCTION public.f(x integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
    'DROP PROCEDURE public.f(INOUT x integer)' ],
  [ 'function to procedure INOUT',
    q{CREATE FUNCTION public.f(x integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
    q{CREATE PROCEDURE public.f(INOUT x integer) LANGUAGE plpgsql AS 'BEGIN END'},
    'DROP FUNCTION public.f(x integer)' ],
  [ 'procedure with OUT to function without',
    q{CREATE PROCEDURE public.f(OUT x integer, IN y integer) LANGUAGE plpgsql AS 'BEGIN x := 1; END'},
    q{CREATE FUNCTION public.f(y integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
    'DROP PROCEDURE public.f(OUT x integer, IN y integer)' ],
  [ 'procedure to function, another argument name',
    q{CREATE PROCEDURE public.f(y integer) LANGUAGE plpgsql AS 'BEGIN END'},
    q{CREATE FUNCTION public.f(z integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
    'DROP PROCEDURE public.f(IN y integer)' ],
) {
  my ($label, $from, $to, $drop) = @$case;
  start_over([ $from ], [ $to ]);
  throws_ok { ops() } qr/\Arefusing to diff: .*under the same argument types/m,
    "$label: refused when the operations are built";
  like $@, qr/\Q$drop\E/, "$label: the message names the way out";

  # The claim behind it: the server does refuse the create alongside.
  ok !eval { $dbh_a->do($to); 1 }, "$label: the server refuses the create beside the old routine";
  like $@, qr/already exists with same argument types/, '... for that reason';

  # And the way out works: drop, then create, and the diff is empty.
  ok eval { $dbh_a->do($_) for "$drop", $to; 1 }, "$label: the manual drop and create run" or diag $@;
  is scalar @{ ops() }, 0, "$label: afterwards the diff is empty";
}

# Keys that pair stay a rebuild, mode OUT and all.
start_over(
  [ q{CREATE FUNCTION public.f(OUT x integer, y integer) LANGUAGE sql AS 'SELECT 1'} ],
  [ q{CREATE PROCEDURE public.f(OUT x integer, IN y integer) LANGUAGE plpgsql AS 'BEGIN x := 1; END'} ],
);
{
  my @sql = map { $_->as_sql } @{ ops() };
  is scalar @sql, 2, 'function with OUT to procedure: paired, two statements';
  ok eval { $dbh_a->do($_) for @sql; 1 }, '... the server takes them' or diag $@;
  is scalar @{ ops() }, 0, '... afterwards the diff is empty';
}

done_testing;
