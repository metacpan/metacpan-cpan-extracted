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

# LIVE test for karr k121 (U8): a change to an existing type.
#
# The diff wrote ALTER TYPE ... ADD VALUE for an enum that gained values and
# nothing for any other change to a type both sides have: a composite type
# with other attributes, a range with another subtype, an enum that lost or
# reordered values, a type that is another kind in the target. No operation
# and no message -- an upgrade that reported success and left the type as it
# was. Measured before the fix: every case of part 1 gave an empty list of
# operations.
#
# With database A as what there is and B as what is wanted:
#
#  1. each of those is refused, naming the type and what differs, and no
#     statement is written for anything;
#  2. what ran before is unchanged: a value appended to an enum is one
#     ALTER TYPE ... ADD VALUE and the server takes it, and the same type on
#     both sides is no operation.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t139a t139b );

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

# --- 1. refused --------------------------------------------------------------

start_over(
  [ q{CREATE TYPE public.t AS (a integer, b text)} ],
  [ q{CREATE TYPE public.t AS (a integer, b text, c boolean)} ],
);
throws_ok { ops() } qr/\Arefusing to diff: composite type public\.t has other attributes in the target than in the database/m,
  'a composite type with another attribute is refused, by name';
like $@, qr/ALTER TYPE/, '... and the message says what to do';
like $@, qr/No statement was generated\./, '... and that no statement was written';

start_over(
  [ q{CREATE TYPE public.t AS (a integer, b text)} ],
  [ q{CREATE TYPE public.t AS (a integer, b varchar(5))} ],
);
throws_ok { ops() } qr/\Arefusing to diff: composite type public\.t has other attributes/m,
  'a composite type with an attribute of another type is refused';

start_over(
  [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = integer)} ],
  [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = bigint)} ],
);
throws_ok { ops() } qr/\Arefusing to diff: range type public\.r has another subtype in the target than in the database/m,
  'a range type with another subtype is refused';

start_over(
  [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'c')} ],
  [ q{CREATE TYPE public.e AS ENUM ('a', 'c')} ],
);
throws_ok { ops() } qr/\Arefusing to diff: enum type public\.e has lost the value\(s\) 'b' in the target/m,
  'an enum that lost a value is refused';

start_over(
  [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'c')} ],
  [ q{CREATE TYPE public.e AS ENUM ('a', 'c', 'b')} ],
);
throws_ok { ops() } qr/\Arefusing to diff: enum type public\.e has its values in another order in the target/m,
  'an enum with its values in another order is refused';

start_over(
  [ q{CREATE TYPE public.t AS ENUM ('a', 'b')} ],
  [ q{CREATE TYPE public.t AS (a integer)} ],
);
throws_ok { ops() } qr/\Arefusing to diff: type public\.t is a composite type in the target and an enum type in the database/m,
  'a type that is another kind in the target is refused';

# --- 2. what ran before ------------------------------------------------------

start_over(
  [ q{CREATE TYPE public.e AS ENUM ('a', 'b')} ],
  [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'c')} ],
);
my @sql = map { $_->as_sql } @{ ops() };
is_deeply \@sql, [ q{ALTER TYPE public.e ADD VALUE 'c';} ], 'an enum that gained a value: one ADD VALUE';
ok eval { $dbh_a->do($_) for @sql; 1 }, '... the server takes it' or diag $@;
is scalar @{ ops() }, 0, '... and afterwards the diff is empty';

# A value between two the database has goes where the target has it. It was
# appended, the type had another order than the target, and the next diff
# refused it as a reordering.
start_over(
  [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'f')} ],
  [ q{CREATE TYPE public.e AS ENUM ('x', 'a', 'c', 'd', 'b', 'e', 'f', 'g')} ],
);
@sql = map { $_->as_sql } @{ ops() };
ok eval { $dbh_a->do($_) for map { split /\n/ } @sql; 1 }, 'values between and around old ones: the server takes them' or diag $@;
is_deeply [ @{ $dbh_a->selectcol_arrayref(
    q{SELECT enumlabel FROM pg_enum WHERE enumtypid = 'public.e'::regtype ORDER BY enumsortorder}) } ],
  [qw(x a c d b e f g)], '... and pg_enum has them in the target order';
is scalar @{ ops() }, 0, '... and afterwards the diff is empty';

start_over(
  [ q{CREATE TYPE public.t AS (a integer, b text)}, q{CREATE TYPE public.r AS RANGE (SUBTYPE = integer)} ],
  [ q{CREATE TYPE public.t AS (a integer, b text)}, q{CREATE TYPE public.r AS RANGE (SUBTYPE = integer)} ],
);
is scalar @{ ops() }, 0, 'the same types on both sides are no operation';

done_testing;
