use strict;
use warnings;
use Test::More;

# t/09-test-schema.t — the live suite's fixture, checked without a server.
#
# DBIO::ClickHouse::Test::Schema is the schema every live file deploys, and a
# live run is a scarce resource: ClickHouse has no in-memory mode, so the
# maintainer starts a real server by hand for ONE serial run. A fixture that is
# broken in a way any offline check could have caught burns that run.
#
# So this file asserts the two properties the live files rely on and that can
# be established with no connection at all:
#
#   1. the schema loads, and its sources are the ones the live files ask for by
#      name (a typo'd source name is a die three files into the live run);
#   2. the install DDL it renders carries the ClickHouse-specific constructs
#      each source exists to deploy -- the engine argument, the partition key,
#      the PRIMARY KEY prefix, ORDER BY tuple(), the escaped enum member and a
#      CREATE VIEW. If any of those silently stopped being emitted, the live
#      round-trip test would still pass (both sides come from the same DDL) and
#      the coverage would be gone without a single failure.
#
# What it does NOT assert is any full statement: t/36-ddl-install.t pins the
# rendering char-for-char against a hand-built schema, and repeating that here
# would only make the fixture painful to extend.

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Test::Schema;

is_deeply
  [ sort DBIO::ClickHouse::Test::Schema->sources ],
  [qw/Hit HotHit Probe Reading Snapshot Unsorted/],
  'the fixture has exactly the sources the live files address by name';

ok(DBIO::ClickHouse::Test::Schema->can('clickhouse_install_ddl'),
  'the ClickHouse component is loaded, so the schema can render its own DDL');

my $ddl = DBIO::ClickHouse::Test::Schema->clickhouse_install_ddl;

# --- the constructs each source exists to put on the wire --------------------

like $ddl, qr/^ENGINE = ReplacingMergeTree\(version\)$/m,
  'Snapshot deploys a parameterized engine -- what engine_full introspection is for';

like $ddl, qr/^PARTITION BY toYYYYMM\(ts\)$/m,
  'Reading deploys a partition key';

like $ddl, qr/^PRIMARY KEY \(`sensor`\)\nORDER BY \(`sensor`, `ts`\);$/m,
  'Reading deploys a PRIMARY KEY that is a strict prefix of the sorting key';

like $ddl, qr/^ORDER BY tuple\(\);$/m,
  'Unsorted deploys the empty sorting key';

like $ddl, qr/^CREATE VIEW `dbio_test_hot_hit` AS /m,
  'HotHit deploys a real view -- the only CREATE VIEW this driver executes';

# --- the type map, as far as it can be checked offline ----------------------

like $ddl, qr/`flag` Bool,/,
  q{boolean deploys as Bool, not UInt8 -- the whole boolean round trip hangs on it};

like $ddl, qr/`d_wide` Date32,/,
  'portable date deploys as Date32 (1900-2299)';
like $ddl, qr/`d_narrow` Date,/,
  '... while the exact native spelling reaches the narrow two-byte type';

like $ddl, qr/`ts_ms` DateTime64\(3\),/,
  'portable datetime deploys with millisecond precision';
like $ddl, qr/`ts_sec` DateTime,/,
  '... while the exact native spelling reaches the second-resolution type';

like $ddl, qr/`state` Enum8\('draft' = 1, 'live' = 2, 'it\\'s' = 3\),/,
  q{the enum member with an apostrophe is escaped as \' -- the wire has to accept it};

like $ddl, qr/`s_low_null` LowCardinality\(Nullable\(String\)\),/,
  'LowCardinality nests outside Nullable';

like $ddl, qr/`tags` Array\(String\),/,
  'an array column is never wrapped in Nullable()';

unlike $ddl, qr/\bJSON\b/,
  'the native JSON type is deliberately absent -- a server that rejects it '
. 'must not take the whole fixture down (t/18-types-live.t probes it alone)';

# --- the fixture row lines up with the table it populates -------------------

my %column = map { $_ => 1 } DBIO::ClickHouse::Test::Schema::Probe->columns;
my @unknown = grep { !$column{$_} } sort keys %{ DBIO::ClickHouse::Test->probe_row };
is_deeply \@unknown, [],
  'every key of probe_row is a real column -- a stale key would be a silent '
. 'insert failure on the live server';

done_testing;
