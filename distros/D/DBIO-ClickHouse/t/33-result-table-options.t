use strict;
use warnings;
use Test::More;

# t/33-result-table-options.t — DBIO::ClickHouse::Result's clickhouse_table,
# the per-result-class table-options API the DDL layer reads. Offline.
#
# The intent: a bad table option must fail when the result class is compiled,
# not when the DDL is deployed against a server — a typo'd engine or a
# misspelled key would otherwise surface as a ClickHouse syntax error hours
# later. Errors go through throw_exception (family rule), never bare croak.

use DBIO::ClickHouse::Result;

{
  package My::CHOpt::Result;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('ClickHouse::Result');
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(id => { data_type => 'uuid' });
  __PACKAGE__->set_primary_key('id');
}

is(My::CHOpt::Result->clickhouse_table, undef,
  'undeclared options read back as undef');

# --- normalization: scalars become arrayrefs, hashes are copied -----------
My::CHOpt::Result->clickhouse_table({
  engine       => 'ReplacingMergeTree(ts)',
  order_by     => 'ts',
  primary_key  => ['ts'],
  partition_by => 'toYYYYMM(ts)',
  settings     => { index_granularity => 8192 }
});

is_deeply(My::CHOpt::Result->clickhouse_table, {
  engine       => 'ReplacingMergeTree(ts)',
  order_by     => ['ts'],
  primary_key  => ['ts'],
  partition_by => 'toYYYYMM(ts)',
  settings     => { index_granularity => 8192 }
}, 'options read back with order_by/primary_key normalized to arrayrefs');

isnt(My::CHOpt::Result->clickhouse_table, My::CHOpt::Result->clickhouse_table,
  'each read returns its own copy, so a caller cannot mutate the class data');

# An explicit empty sorting key is legal — it renders ORDER BY tuple().
{
  package My::CHOpt::Unsorted;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('ClickHouse::Result');
  __PACKAGE__->table('u');
  __PACKAGE__->clickhouse_table({ order_by => [] });
}
is_deeply(My::CHOpt::Unsorted->clickhouse_table, { order_by => [] },
  'an explicit empty order_by survives validation');

# --- validation ----------------------------------------------------------
my %bad = (
  'not a hashref'        => 'MergeTree',
  'unknown option'       => { engien => 'MergeTree' },
  'empty engine'         => { engine => '' },
  'engine as arrayref'   => { engine => ['MergeTree'] },
  'partition_by ref'     => { partition_by => ['toYYYYMM(ts)'] },
  'order_by hashref'     => { order_by => [{ ts => 1 }] },
  'order_by empty entry' => { order_by => ['ts', ''] },
  'settings not a hash'  => { settings => 'index_granularity=8192' },
  'settings hashref val' => { settings => { x => { y => 1 } } }
);

for my $case (sort keys %bad) {
  eval { My::CHOpt::Result->clickhouse_table($bad{$case}); 1 };
  my $err = $@;
  ok $err, "rejected: $case";
  isa_ok $err, 'DBIO::Exception', "  error for '$case'";
  like "$err", qr/clickhouse_table\(\)/, "  message names the API: $case";
}

# A rejected call must not have clobbered the previously stored options.
is_deeply(My::CHOpt::Result->clickhouse_table->{order_by}, ['ts'],
  'a failed set leaves the stored options untouched');

# --- standalone use (no result class in the MRO) --------------------------
eval { DBIO::ClickHouse::Result->clickhouse_table('nope'); 1 };
isa_ok $@, 'DBIO::Exception',
  'validation still throws when the component is used outside a result class';

done_testing;
