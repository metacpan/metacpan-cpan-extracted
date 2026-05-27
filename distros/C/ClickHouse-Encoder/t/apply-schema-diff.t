use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# apply_schema_diff: schema_diff -> alter table statements. The ordering
# is load-bearing: drops first, then modifies, then adds, so a column
# rename modeled as drop+add doesn't trip over a pre-existing column
# of the same name.

my $diff = ClickHouse::Encoder->schema_diff(
    [ [id => 'UInt64'], [name => 'String'], [old => 'Int32'] ],
    [ [id => 'UInt64'], [name => 'LowCardinality(String)'], [created => 'DateTime'] ],
);

my $sql = ClickHouse::Encoder->apply_schema_diff($diff, table => 'events');

is_deeply($sql, [
    "alter table `events` drop column `old`",
    "alter table `events` modify column `name` LowCardinality(String)",
    "alter table `events` add column `created` DateTime",
], 'apply_schema_diff: drops -> modifies -> adds (in that order)');

# Backtick-containing identifiers (rare but legal in CH) must be
# escaped so the emitted SQL is parseable. CH quotes with backticks
# itself in show create table output so we match that style.
$diff = ClickHouse::Encoder->schema_diff(
    [],
    [ ['weird`name', 'Int32'] ],
);
$sql = ClickHouse::Encoder->apply_schema_diff($diff, table => 'tbl');
is($sql->[0], 'alter table `tbl` add column `weird\\`name` Int32',
   'apply_schema_diff: backtick in column name is escaped');

# No-op diff -> empty arrayref (caller decides whether to issue any
# statements at all).
$diff = ClickHouse::Encoder->schema_diff(
    [ [id => 'UInt64'] ],
    [ [id => 'UInt64'] ],
);
is_deeply(ClickHouse::Encoder->apply_schema_diff($diff, table => 't'), [],
          'apply_schema_diff: empty diff -> no statements');

# Missing 'table' opt must croak loudly - emitting "alter table  drop ..."
# would only fail at the server with an obscure parse error.
local $@;
eval { ClickHouse::Encoder->apply_schema_diff({ added => [] }) };
like($@, qr/table.+required/i,
     'apply_schema_diff: missing table croaks before emitting SQL');

# Invalid table names are rejected at the helper boundary, matching
# the policy of the rest of the public-API surface (format_create_table,
# for_table, etc.).
eval { ClickHouse::Encoder->apply_schema_diff(
    { added => [['c','Int32']] }, table => "; drop table users;--") };
ok($@, 'apply_schema_diff: rejects injection-shaped table names');

done_testing();
