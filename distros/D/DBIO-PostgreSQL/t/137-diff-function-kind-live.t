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

# Folded from several live files by subject (karr k158): every old file is a
# subtest named after it, with its own private database(s) as before, and
# its helpers in a package block of its own, since named subs and the
# lexicals they close over are file-global otherwise.

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
{
  package Fold137::FunctionKind;
  use Test::More;
  use Test::Exception;

  my ($dbh_a, $dbh_b);

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

  subtest 'diff-function-kind' => sub {
  ($dbh_a, $dbh_b) = map {
    my $h = LiveServer->control_dbh(
      login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
    $h->do('SET client_min_messages = warning');
    # PostgreSQL reports in the language of lc_messages; the test reads the
    # server's English words (already exists with same argument types)
    $h->do(q{SET lc_messages = 'C'});
    $h;
  } qw( t137a t137b );

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
  };
}

# LIVE test for karr k121 (U7, points 3 and 4), the cases the diff-function-kind subtest above does not hold:
# what a routine that changes kind has around it, and the kinds that are not
# a function or a procedure.
#
# Measured before this file (the table is in the card): none of the cases
# below was silent. Every one of them is green on the code as it stood; the
# file holds them so that they stay what they are. With database A as what
# there is and B as what is wanted:
#
#  1. a function that becomes a procedure (and back) is dropped and created
#     again under named arguments, under overloads (one routine of the name
#     changes, the other stays) and with a type of another schema among the
#     arguments, and the statements run;
#  2. a procedure that becomes a trigger function, with the trigger that
#     uses it, runs: the function is created ahead of the trigger;
#  3. a function that becomes a procedure while a trigger or a column default
#     still uses it is NOT silent and not refused by the diff: the DROP is
#     written, the server refuses it ("cannot drop function ... because other
#     objects depend on it"), and the transaction around the statements
#     leaves the database as it was. The diff does not write DROP ... CASCADE;
#  4. a function and an aggregate (or a procedure and an aggregate) under one
#     signature are refused in both directions, naming both -- the aggregate
#     has no definition to create the other from.
{
  package Fold137::FunctionKindDependents;
  use Test::More;
  use Test::Exception;

  my ($dbh_a, $dbh_b);

  sub catalog {
    my ($dbh) = @_;
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
    delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
    return $model;
  }

  sub start_over {
    my ($sql_a, $sql_b) = @_;
    for my $dbh ($dbh_a, $dbh_b) {
      $dbh->do($_) for 'DROP SCHEMA IF EXISTS s CASCADE', 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
    }
    $dbh_a->do($_) for @$sql_a;
    $dbh_b->do($_) for @$sql_b;
  }

  sub ops {
    return DBIO::PostgreSQL::Diff->new(
      source => catalog($dbh_a), target => catalog($dbh_b))->operations;
  }

  # The statements in one transaction, as Deploy->apply runs them.
  sub apply {
    my (@sql) = @_;
    $dbh_a->begin_work;
    return 1 if eval { $dbh_a->do($_) for @sql; $dbh_a->commit; 1 };
    my $error = $@;
    $dbh_a->rollback;
    return (0, $error);
  }

  sub routines {
    return join ',', map { join '/', @$_ } @{ $dbh_a->selectall_arrayref(
      q{SELECT p.proname, p.prokind FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname IN ('public', 's') ORDER BY 1, 2}) };
  }

  subtest 'diff-function-kind-dependents' => sub {
  ($dbh_a, $dbh_b) = map {
    my $h = LiveServer->control_dbh(
      login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
    $h->do('SET client_min_messages = warning');
    # PostgreSQL reports in the language of lc_messages; the test reads the
    # server's English words, so its sessions are set to 'C'
    $h->do(q{SET lc_messages = 'C'});
    $h;
  } qw( t171a t171b );

  # --- 1. around the rebuild ---------------------------------------------------

  for my $case (
    [ 'named arguments, function to procedure',
      [ q{CREATE FUNCTION public.f(a integer, b text) RETURNS integer LANGUAGE sql AS 'SELECT 1'} ],
      [ q{CREATE PROCEDURE public.f(IN a integer, IN b text) LANGUAGE sql AS 'SELECT 1'} ], 'f/p' ],
    [ 'named arguments, procedure to function',
      [ q{CREATE PROCEDURE public.f(IN a integer, IN b text) LANGUAGE sql AS 'SELECT 1'} ],
      [ q{CREATE FUNCTION public.f(a integer, b text) RETURNS integer LANGUAGE sql AS 'SELECT 1'} ], 'f/f' ],
    [ 'one of two overloads',
      [ q{CREATE FUNCTION public.f(integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'},
        q{CREATE FUNCTION public.f(text) RETURNS integer LANGUAGE sql AS 'SELECT 2'} ],
      [ q{CREATE PROCEDURE public.f(IN integer) LANGUAGE sql AS 'SELECT 1'},
        q{CREATE FUNCTION public.f(text) RETURNS integer LANGUAGE sql AS 'SELECT 2'} ], 'f/f,f/p' ],
    [ 'a type of another schema among the arguments',
      [ q{CREATE SCHEMA s}, q{CREATE TYPE s.st AS ENUM ('a')},
        q{CREATE FUNCTION s.f(s.st) RETURNS integer LANGUAGE sql AS 'SELECT 1'} ],
      [ q{CREATE SCHEMA s}, q{CREATE TYPE s.st AS ENUM ('a')},
        q{CREATE PROCEDURE s.f(IN s.st) LANGUAGE sql AS 'SELECT 1'} ], 'f/p' ],
  ) {
    my ($label, $from, $to, $want) = @$case;
    start_over($from, $to);
    my @sql = map { $_->as_sql } @{ ops() };
    is scalar @sql, 2, "$label: two statements";
    like $sql[0] // '', qr/\ADROP (?:FUNCTION|PROCEDURE) /, "$label: the old one is dropped first";
    my ($ok, $error) = apply(@sql);
    ok $ok, "$label: the server takes them" or diag $error;
    is routines(), $want, "$label: the database has the routines wanted";
    is scalar @{ ops() }, 0, "$label: afterwards the diff is empty";
  }

  # --- 2. a procedure that becomes a trigger function --------------------------

  start_over(
    [ q{CREATE TABLE public.t (id integer)},
      q{CREATE PROCEDURE public.trg() LANGUAGE sql AS 'SELECT 1'} ],
    [ q{CREATE TABLE public.t (id integer)},
      q{CREATE FUNCTION public.trg() RETURNS trigger LANGUAGE plpgsql AS $$BEGIN RETURN NEW; END$$},
      q{CREATE TRIGGER tg BEFORE INSERT ON public.t FOR EACH ROW EXECUTE FUNCTION public.trg()} ],
  );
  {
    my @sql = map { $_->as_sql } @{ ops() };
    like $sql[0], qr/\ADROP PROCEDURE public\.trg\(\);\z/, 'procedure to trigger function: the procedure goes first';
    like $sql[1], qr/\ACREATE OR REPLACE FUNCTION public\.trg\(\)/, '... then the function';
    like $sql[2], qr/\ACREATE TRIGGER tg /, '... then the trigger that uses it';
    my ($ok, $error) = apply(@sql);
    ok $ok, '... the server takes them' or diag $error;
    is scalar @{ ops() }, 0, '... and afterwards the diff is empty';
  }

  # --- 3. a function in use becomes a procedure --------------------------------

  for my $case (
    [ 'a trigger uses it',
      [ q{CREATE TABLE public.t (id integer)},
        q{CREATE FUNCTION public.trg() RETURNS trigger LANGUAGE plpgsql AS $$BEGIN RETURN NEW; END$$},
        q{CREATE TRIGGER tg BEFORE INSERT ON public.t FOR EACH ROW EXECUTE FUNCTION public.trg()} ],
      [ q{CREATE TABLE public.t (id integer)},
        q{CREATE PROCEDURE public.trg() LANGUAGE sql AS 'SELECT 1'} ],
      qr/trigger tg on table t depends on function trg\(\)/ ],
    [ 'a column default uses it',
      [ q{CREATE FUNCTION public.f() RETURNS integer LANGUAGE sql AS 'SELECT 1'},
        q{CREATE TABLE public.t (id integer DEFAULT public.f())} ],
      [ q{CREATE PROCEDURE public.f() LANGUAGE sql AS 'SELECT 1'},
        q{CREATE TABLE public.t (id integer)} ],
      qr/default value for column id of table t depends on function f\(\)/ ],
  ) {
    my ($label, $from, $to, $detail) = @$case;
    start_over($from, $to);
    my @sql = map { $_->as_sql } @{ ops() };
    like $sql[0] // '', qr/\ADROP FUNCTION public\.\w+\(\);\z/, "$label: the DROP is written, without CASCADE";
    my $before = routines();
    my ($ok, $error) = apply(@sql);
    ok !$ok, "$label: the server refuses the statements";
    like $error, qr/cannot drop function \w+\(\) because other objects depend on it/, '... saying why';
    like $error, $detail, '... and what depends on it';
    is routines(), $before, '... and the transaction leaves the database as it was';
  }

  # A procedure with an INOUT argument that becomes a function: the mode is
  # part of the key and of the pairing, so the two are not taken for one
  # routine, yet the server keeps one routine per name and input argument types.
  # The diff refuses ahead, when the operations are built (karr k121; it used to
  # write the statements and leave the refusal to the server at the apply).
  start_over(
    [ q{CREATE PROCEDURE public.f(INOUT x integer) LANGUAGE plpgsql AS $$BEGIN END$$} ],
    [ q{CREATE FUNCTION public.f(x integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: procedure public\.f\(INOUT x integer\) is in the database and function public\.f\(x integer\) is in the target, under the same argument types/,
    'an INOUT procedure to a function: refused when the operations are built';
  like $@, qr/DROP PROCEDURE public\.f\(INOUT x integer\)/, '... naming the way out';

  # --- 4. an aggregate and another kind under one signature --------------------

  my $agg  = q{CREATE AGGREGATE public.mysum(integer) (SFUNC = int4pl, STYPE = integer)};
  my $func = q{CREATE FUNCTION public.mysum(integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'};
  my $proc = q{CREATE PROCEDURE public.mysum(IN integer) LANGUAGE sql AS 'SELECT 1'};

  for my $case (
    [ 'function to aggregate',  [ $func ], [ $agg ],  qr/\Arefusing to diff: aggregate public\.mysum\(integer\) is in the target, and the database has function public\.mysum\(integer\) of the same signature/ ],
    [ 'aggregate to function',  [ $agg ],  [ $func ], qr/\Arefusing to diff: function public\.mysum\(integer\) is in the target, and the database has aggregate public\.mysum\(integer\) of the same signature/ ],
    [ 'procedure to aggregate', [ $proc ], [ $agg ],  qr/\Arefusing to diff: aggregate public\.mysum\(integer\) is in the target, and the database has procedure public\.mysum\(IN integer\) of the same signature/ ],
    [ 'aggregate to procedure', [ $agg ],  [ $proc ], qr/\Arefusing to diff: procedure public\.mysum\(IN integer\) is in the target, and the database has aggregate public\.mysum\(integer\) of the same signature/ ],
  ) {
    my ($label, $from, $to, $re) = @$case;
    start_over($from, $to);
    throws_ok { ops() } $re, "$label: refused, naming both";
    like $@, qr/No statement was generated\./, '... and no statement written';
  }
  };
}

done_testing;
