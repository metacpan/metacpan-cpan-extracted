use strict;
use warnings;
use Test::More;

# LIVE test for the karr #22 WP2 / core #70 '?' seam contract, end to end: the
# transport's query seam is fed SQL in the sql_maker '?' dialect and must shape
# it to PostgreSQL '$N' INTERNALLY (DBIO::PostgreSQL::EV::Storage::_transform_sql)
# before it reaches libpq -- and SQL already in '$N' form must pass through
# unchanged. Offline coverage of the shaping itself is in t/03 and
# t/06-thin-transport-structure.t; this proves the rows actually come back
# correct against a real server.
#
# Dogfoods DBIO::PostgreSQL::EV::TestHarness.

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

my $h = DBIO::PostgreSQL::EV::TestHarness->new;
my $async = $h->async;

# --- '?' dialect fed to _query_async resolves correct rows -------------------
{
  my @rows = $h->await(
    $async->_query_async('SELECT ?::int AS n, ?::text AS s', [ 42, 'hi' ])
  );
  is scalar(@rows), 1, 'single row returned for a ? query';
  is $rows[0][0], 42,   'first ? bound and returned correctly ($1)';
  is $rows[0][1], 'hi', 'second ? bound and returned correctly ($2)';
}

# --- multiple '?' numbered left-to-right across the statement ----------------
{
  my @rows = $h->await(
    $async->_query_async('SELECT ?::int AS a, ?::int AS b, ?::int AS c', [ 10, 20, 30 ])
  );
  is_deeply $rows[0], [ 10, 20, 30 ],
    'three ? placeholders numbered $1,$2,$3 in order';
}

# --- '$N' passthrough stays intact (idempotent shaping) ----------------------
{
  my @rows = $h->await(
    $async->_query_async('SELECT $1::int AS n', [ 7 ])
  );
  is $rows[0][0], 7, 'SQL already in $N form passes through and resolves correctly';
}

# --- the JSONB '@?' operator survives while a real ? beside it is shaped ------
# '@?' is the jsonpath operator; its literal '?' must NOT be treated as a bind,
# but a separate '?' placeholder must still become $1.
{
  my @rows = $h->await(
    $async->_query_async(
      q{SELECT ('{"a":1}'::jsonb @? '$.a ? (@ == 1)') AS matched, ?::int AS n},
      [ 5 ],
    )
  );
  ok $rows[0][0], 'jsonb @? operator preserved (matched true), literal ? not bound';
  is $rows[0][1], 5, 'the real ? beside @? still became a bound $1';
}

$h->disconnect;

done_testing;
