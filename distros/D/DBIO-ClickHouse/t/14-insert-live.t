use strict;
use warnings;
use Test::More;

# t/14-insert-live.t — the insert path against a live ClickHouse server,
# reached over the MySQL wire protocol.
#
# ClickHouse has NO embedded / in-memory mode, so this cannot run unattended:
# it needs a real server and is gated on DBIO_TEST_CLICKHOUSE_DSN. Without it
# the file skips cleanly. The offline contract for the same code is
# t/13-insert.t, which pins the rendered SQL and the bind order without a
# server.
#
# What this file is for is the half t/13 cannot reach — every assertion here is
# an assumption about the server or the wire, not about our rendering:
#
#   * a multi-row INSERT ... VALUES (...), (...), ... is accepted at all over
#     the MySQL wire handler, and its placeholders bind positionally, so row 2
#     column 3 really lands in row 2 column 3 (a bind-order bug is invisible
#     offline: the SQL would still be right);
#   * DEFAULT generateUUIDv4() fires for a bulk insert that omits the column,
#     which is the whole reason the DDL layer emits it;
#   * a client-generated UUID string is accepted by a UUID column and comes
#     back byte-identical, which is what makes $row->id trustworthy;
#   * a batch of a few thousand rows survives one statement (max_allowed_packet
#     on the MySQL handler is not something we can reason about offline).

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;

# The table under test is the fixture's Hit source -- plain MergeTree, UUID key,
# "the source the insert and mutation paths run against"
# (DBIO::ClickHouse::Test::Schema::Hit). It is deliberately not a result class
# written here: a second definition of the same table would be a second thing to
# keep in step with the DDL layer, and it would not be the table the rest of the
# live suite deploys.
#
# init_schema deploys into this process's own database and drops that database
# again in an END block, so nothing here can collide with another file and no
# cleanup is left for a failed assertion to skip. See
# DBIO::ClickHouse::Test/EVERY TEST PROCESS GETS ITS OWN DATABASE. Deploying is
# also what puts the emitted DEFAULT generateUUIDv4() under test.
#
# no_populate, because every count below is an absolute number: this file needs
# the table empty, not carrying the six fixture rows.
my $schema = DBIO::ClickHouse::Test->init_schema(no_populate => 1);

my $rs = $schema->resultset('Hit');

# --- the batch round-trip ---------------------------------------------------
#
# Distinct hits per url: if the multi-row placeholders bound in the wrong
# order, the statement would still succeed and the count would still be 3 --
# only the pairing would be wrong. That pairing is the assertion.
{
  my %expected = ( '/a' => 1, '/b' => 22, '/c' => 333 );

  $rs->populate([ map { { url => $_, hits => $expected{$_} } } sort keys %expected ]);

  is $rs->count, 3, 'a three-row populate() wrote three rows';

  my %got = map { $_->url => $_->hits } $rs->all;
  is_deeply \%got, \%expected,
    'every value landed in its own row and column -- binds are positional';

  my @ids = map { $_->id } $rs->all;
  is scalar(grep { defined && length } @ids), 3,
    'DEFAULT generateUUIDv4() filled the omitted key for the bulk insert';
  is scalar(keys %{ { map { $_ => 1 } @ids } }), 3,
    '... with a distinct UUID per row';
}

# --- a client-generated UUID survives the wire ------------------------------
{
  my $row = $rs->create({ url => '/created', hits => 7 });

  like $row->id,
    qr/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/,
    'create() returns the UUID this process generated';

  my $found = $rs->find($row->id);
  ok $found, 'the row is findable by exactly that id -- the server stored it verbatim';
  is $found->url, '/created', '... and carries the rest of the row';
}

# --- literal SQL per row ----------------------------------------------------
#
# Rows are rendered individually, so one may use literal SQL where the next
# uses a bind. Nothing offline can prove the server accepts the mixture.
{
  my $before = $rs->count;

  $rs->populate([
    { id => \'generateUUIDv4()', url => '/lit', hits => 1 },
    { id => '11111111-2222-4333-8444-555555555555', url => '/plain', hits => 2 }
  ]);

  is $rs->count, $before + 2, 'a row with a literal key and one with a bound key both wrote';
  ok $rs->find('11111111-2222-4333-8444-555555555555'),
    '... and the explicitly supplied key was not replaced';
}

# --- a batch big enough to be a batch ---------------------------------------
#
# One statement carries one placeholder per cell. This is the cheapest probe of
# where the MySQL handler's packet limit sits; if it fails, the driver needs a
# chunking story (and the POD's "chunk it yourself" advice needs a number).
{
  my $before = $rs->count;
  my $n = 2_000;

  $rs->populate([ map { { url => "/bulk/$_", hits => $_ } } 1 .. $n ]);

  is $rs->count, $before + $n, "a $n-row populate() went through as one statement";
  is $rs->search({ url => '/bulk/1999' })->single->hits, 1999,
    '... with the last rows still correctly paired';
}

done_testing;
