use strict;
use warnings;
use Test::More;

# t/17-smoke-live.t — does the driver work at all against a real ClickHouse
# server, reached over the MySQL wire protocol.
#
# ClickHouse has NO embedded / in-memory mode, so this cannot run unattended:
# it needs a real server and is gated on DBIO_TEST_CLICKHOUSE_DSN. Without it
# the file skips cleanly.
#
# This is the file that has to pass before any other live file is worth
# reading. It is deliberately the widest and the shallowest of them: connect,
# deploy the whole fixture, populate it, and then take one pass through the
# ordinary ORM surface -- count, search, create, find, a join, a view, a NULL.
# Everything here is something every other live file silently assumes.
#
# The one assumption it exists to settle on its own account is the LIMIT
# clause. DBIO::SQLMaker::ClassicExtensions::apply_limit emits `LIMIT ? OFFSET ?`
# -- bound placeholders, not inlined integers -- and nothing offline can say
# whether ClickHouse's MySQL-wire handler takes them. If it does not, that is
# not a detail: it means every paged resultset on this driver is broken, and
# DBIO::ClickHouse::SQLMaker's decision to inline the `LIMIT n BY` count
# (rather than bind it) becomes the rule rather than the exception.
#
# Note the scope of that answer. Both MySQL-wire DBDs default to CLIENT-side
# placeholder interpolation (DBD::MariaDB's mariadb_server_prepare is 0 unless
# asked for), so what is being proven is that the driver's paging works in the
# configuration everyone actually runs -- not that ClickHouse implements
# COM_STMT_PREPARE. A schema connected with server-side prepares turned on is a
# different question and is not asked anywhere in this suite.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;

my $schema = DBIO::ClickHouse::Test->init_schema;

isa_ok $schema->storage, 'DBIO::ClickHouse::Storage', 'the pinned storage';

my $version = $schema->storage->clickhouse_version;
ok $version, 'clickhouse_version() answered';
diag "ClickHouse server version: " . ($version // '(none)');
diag 'test database: ' . DBIO::ClickHouse::Test->test_database;

# --- the fixture deployed and populated -------------------------------------
#
# Deploying is the assertion: DBIO::ClickHouse::Deploy->install runs every
# CREATE TABLE with RaiseError, so a type the server rejects has already killed
# this file above. The counts below only confirm the rows arrived.

is $schema->resultset('Hit')->count,      6, 'hit rows populated';
is $schema->resultset('Snapshot')->count, 3, 'snapshot rows populated';
is $schema->resultset('Reading')->count,  4, 'reading rows populated';
is $schema->resultset('Unsorted')->count, 2, 'ORDER BY tuple() table takes rows';
is $schema->resultset('Probe')->count,    1, 'the type-probe row was accepted';

# The view is a real CREATE VIEW (see DBIO::ClickHouse::Test::Schema::HotHit),
# so querying it proves the statement DBIO::ClickHouse::DDL::Emit::create_view
# renders is one the server can execute.
is $schema->resultset('HotHit')->count, 4,
  'the deployed view is queryable and filters (hits >= 100)';

# --- LIMIT and OFFSET arrive as bound placeholders ---------------------------

{
  my $rs = $schema->resultset('Hit')->search(undef, { order_by => 'me.hits' });

  is_deeply [ map { $_->url } $rs->search(undef, { rows => 2 })->all ],
    [qw(/a /b)],
    'LIMIT ? binds -- a plain paged resultset works';

  is_deeply [ map { $_->url } $rs->search(undef, { rows => 2, offset => 1 })->all ],
    [qw(/b /c)],
    'LIMIT ? OFFSET ? binds -- and the offset is applied, not ignored';

  is_deeply [ map { $_->url } $rs->search(undef, { rows => 2, offset => 4 })->all ],
    [qw(/e /f)],
    '... including an offset that reaches the end of the table';
}

# --- ordinary reads ----------------------------------------------------------

is $schema->resultset('Hit')->search({ hits => { '>' => 100 } })->count, 3,
  'a WHERE with a bound comparison';

is $schema->resultset('Hit')->search({ url => '/f' })->single->ts, undef,
  'a NULL in a Nullable(DateTime64(3)) column comes back as undef';

is $schema->resultset('Reading')->search({ sensor => 'a' })->count, 2,
  'a LowCardinality(String) column can be searched on';

# --- a join over metadata-only relationships --------------------------------
#
# ClickHouse has no foreign keys at all (docs/adr/0004-no-foreign-keys.md), so
# the relationship exists only in DBIO. The join has to work anyway.

{
  my $row = $schema->resultset('Hit')->search(
    { 'me.url' => '/c' }, { prefetch => 'snapshot_row' },
  )->single;

  ok $row, 'found the hit';
  is $row->snapshot_row->label, 'beta',
    'a prefetched LEFT JOIN resolves across a relationship the database does not know about';
}

# --- create(), i.e. the client-side UUID identity ---------------------------

{
  my $rs  = $schema->resultset('Hit');
  my $row = $rs->create({ url => '/created', hits => 7, snapshot => 1 });

  like $row->id,
    qr/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/,
    'create() returned the UUID this process generated and sent';

  my $found = $rs->find($row->id);
  ok $found, 'the row is findable by exactly that key';
  is $found->hits, 7, '... and carries the rest of the row';
  is $rs->count, 7, '... and the table grew by exactly one row';
}

done_testing;
