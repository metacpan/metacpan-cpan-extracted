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

# LIVE measurement for karr k121 (point 14): ALTER TYPE ... RENAME of a range
# type. From PostgreSQL 14 a range type has a multirange type of its own that
# the server names itself (int4range_x -> int4multirange_x). The server does NOT
# rename it with the range. Does the rename leave a follow-up diff?
#
# Measured: no. The model holds the range type only (Introspect::Types reads
# pg_range by rngtypid, and a multirange is neither a range, enum nor
# composite row), so
#
#  1. a range under one name in A and another in B is a drop and a create of a
#     range type, and nothing about a multirange;
#  2. after a manual ALTER TYPE old RENAME TO new in A the multirange keeps
#     its old name (so A's multirange is int4multirange_x, B's is
#     int4multirange_y, and nothing compares them), the model shows the range
#     under the new name only, and the second diff is empty.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t151a t151b );

plan skip_all => 'multirange types need PostgreSQL 14 or later'
  if $dbh_a->{pg_server_version} < 140000;

sub catalog {
  my ($dbh) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

sub diff {
  return DBIO::PostgreSQL::Diff->new(
    source => catalog($dbh_a), target => catalog($dbh_b));
}

sub ops { my $o = diff()->operations; return @$o }

sub multiranges {
  my ($dbh) = @_;
  return $dbh->selectcol_arrayref(q{
    SELECT m.typname
    FROM pg_catalog.pg_type m
    JOIN pg_catalog.pg_range r ON r.rngmultitypid = m.oid
    JOIN pg_catalog.pg_namespace n ON n.oid = m.typnamespace
    WHERE n.nspname = 'public' ORDER BY 1
  });
}

$dbh_a->do('CREATE TYPE public.int4range_x AS RANGE (SUBTYPE = int4)');
$dbh_b->do('CREATE TYPE public.int4range_y AS RANGE (SUBTYPE = int4)');

is_deeply multiranges($dbh_a), ['int4multirange_x'], 'A: the server named the multirange';

# --- 1. the diff between the two names -----------------------------------------

my $model_a = catalog($dbh_a);
is_deeply [ sort keys %{ $model_a->{types} } ], ['public.int4range_x'],
  'the model holds the range type and no multirange type';

my $text = diff()->as_sql;
like $text, qr/CREATE TYPE public\.int4range_y AS RANGE \(SUBTYPE = integer\);/,
  'the diff creates the range under its new name';
like $text, qr/DROP TYPE public\.int4range_x/, '... and drops the old one';
unlike $text, qr/multirange/i, '... and says nothing of a multirange';

# --- 2. after the rename -------------------------------------------------------

$dbh_a->do('ALTER TYPE public.int4range_x RENAME TO int4range_y');

is_deeply multiranges($dbh_a), ['int4multirange_x'],
  'the server leaves the multirange under its old name';
is_deeply multiranges($dbh_b), ['int4multirange_y'],
  '... so the two databases differ in a multirange name the model does not hold';
is_deeply [ sort keys %{ catalog($dbh_a)->{types} } ], ['public.int4range_y'],
  'the model shows the range under the new name';
is_deeply [ ops() ], [], 'the second diff is empty';

done_testing;
