use strict;
use warnings;
use Test::More;

# t/18-types-live.t — the type map, end to end, against a real ClickHouse
# server reached over the MySQL wire protocol.
#
# ClickHouse has NO embedded / in-memory mode, so this cannot run unattended:
# it needs a real server and is gated on DBIO_TEST_CLICKHOUSE_DSN. Without it
# the file skips cleanly. The offline counterpart is t/31-ddl-column-type.t,
# which pins what DBIO::ClickHouse::DDL renders for a given column_info without
# a server.
#
# Three separate questions, in the order they can break:
#
#   1. Does the server ACCEPT every type the map can emit? That is answered by
#      the CREATE TABLE in DBIO::ClickHouse::Test->init_schema, before a single
#      assertion here runs -- DBIO::ClickHouse::Test::Schema::Probe exists to
#      have one column per branch of DBIO::ClickHouse::DDL/Type mapping.
#
#   2. Does the CATALOG report those types back the way this driver assumes?
#      That is what makes the whole test-deploy-and-compare strategy work, and
#      the sharpest case is `Bool`: it is an alias for UInt8 inside the engine,
#      so if system.columns reported UInt8 the DDL layer's deliberate choice of
#      `Bool` over `UInt8` (DBIO::ClickHouse::DDL/Type mapping) would produce a
#      MODIFY COLUMN on every single upgrade, forever.
#
#   3. Do VALUES survive the round trip through the MySQL wire protocol?
#      Above all the ones the type choices were made for: a pre-1970 date
#      (why `date` is Date32 and not Date), sub-second time (why `datetime` is
#      DateTime64(3)), and the enum member whose apostrophe has to be escaped
#      as \' on the way out and come back intact.
#
# The native JSON type is probed last, on a table of its own, because its
# availability depends on the server version -- see the section header.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Diff::Column qw(norm_clickhouse_type);

my $schema = DBIO::ClickHouse::Test->init_schema;
my $dbh    = $schema->storage->dbh;

# --- 2. what the catalog reports back ----------------------------------------

my %type;
{
  my $rows = $dbh->selectall_arrayref(q{
    SELECT name, type FROM system.columns
    WHERE database = currentDatabase() AND table = 'dbio_test_probe'
  });
  $type{ $_->[0] } = norm_clickhouse_type($_->[1]) for @$rows;
}

is $type{flag}, 'Bool',
  'system.columns reports Bool, not the UInt8 it is an alias for -- the DDL '
. 'layer maps boolean to Bool precisely so the two sides stay comparable';

is $type{d_wide}, 'Date32',
  'portable date really is the wide 1900-2299 type on the server';

is $type{state}, q{Enum8('draft' = 1, 'live' = 2, 'it\'s' = 3)},
  q{the enum came back with its members intact, apostrophe and all -- the \' }
. 'escaping DBIO::ClickHouse::DDL::Emit emits survived the wire';

is_deeply \%type, {
  id  => 'Int32',
  i8  => 'Int8',
  i16 => 'Int16',
  i64 => 'Int64',
  u32 => 'UInt32',
  u64 => 'UInt64',

  f32    => 'Float32',
  f64    => 'Float64',
  dec    => 'Decimal(10, 2)',
  amount => 'Decimal(19, 4)',

  s_var  => 'String',
  s_text => 'String',
  s_blob => 'String',
  s_json => 'String',

  s_fixed    => 'FixedString(3)',
  s_low      => 'LowCardinality(String)',
  s_low_null => 'LowCardinality(Nullable(String))',

  flag => 'Bool',
  guid => 'UUID',
  ip   => 'IPv4',

  d_wide   => 'Date32',
  d_narrow => 'Date',
  ts_ms    => 'DateTime64(3)',
  ts_sec   => 'DateTime',
  ts_utc   => q{DateTime64(3, 'UTC')},
  t_str    => 'String',

  state => q{Enum8('draft' = 1, 'live' = 2, 'it\'s' = 3)},

  tags => 'Array(String)',
  nums => 'Array(Int32)',

  note    => 'Nullable(String)',
  title   => 'String',
  counter => 'Int64'
}, 'every column of the type probe reports back exactly the type it was '
 . 'deployed with -- anything else is a phantom diff on every upgrade';

# --- 3. values over the wire --------------------------------------------------

my $sent = DBIO::ClickHouse::Test->probe_row;
my $row  = $schema->resultset('Probe')->find(1);
ok $row, 'the probe row is findable by its key';

for my $col (qw(
  i8 i16 i64 u32 u64 f32 f64 amount
  s_var s_text s_blob s_json s_low
  guid ip d_narrow ts_sec t_str state title
)) {
  is $row->get_column($col), $sent->{$col}, "$col round-tripped unchanged";
}

is $row->get_column('flag'), 1,
  'a Bool column comes back as 1 -- the MySQL wire renders it as its UInt8 value';

is $row->get_column('note'), undef,
  'a NULL in Nullable(String) comes back as undef';
is $row->get_column('s_low_null'), undef,
  'a NULL in LowCardinality(Nullable(String)) comes back as undef';

is $row->get_column('counter'), 7,
  'an explicitly supplied value beats the column DEFAULT';

# The value the date type choice exists for.
is $row->get_column('d_wide'), '1900-01-01',
  'a pre-1970 date survives -- which is the entire reason portable date maps '
. 'to Date32 rather than the two-byte Date';

# --- the wire reformats what it returns --------------------------------------
#
# Three values come back as a DIFFERENT STRING than they went out as, for two
# reasons, and both are the transport's rendering rather than anything happening
# to the data:
#
#   * Decimal(10, 2) drops the trailing zero of its scale -- '12345678.90' is
#     stored, '12345678.9' comes back;
#   * DateTime64(3) is padded out to microseconds -- '2024-05-06 07:08:09.123'
#     is stored, '2024-05-06 07:08:09.123000' comes back, because the MySQL
#     wire's temporal format carries six fractional digits and ClickHouse fills
#     the three it does not have with zeros.
#
# Neither loses anything: the server still holds Decimal(10, 2) and
# DateTime64(3), which is asserted from system.columns above, and every
# significant digit is present. It IS surprising for a caller who compares
# strings, so it is worth saying out loud -- hence the note, which names both
# forms on every live run.
#
# What must NOT happen is pinning the returned string: that would make this file
# a test of DBD::MariaDB's formatting, red on the next DBD or server upgrade for
# a reason that has nothing to do with the driver, and it would stop being a
# test of the thing that matters -- that the milliseconds and the decimal digits
# survive the round trip. So both sides lose their trailing fractional zeros and
# the VALUES are compared.

sub without_trailing_zeros {
  my ($value) = @_;
  return $value unless defined $value && $value =~ /\./;
  $value =~ s/0+\z//;
  $value =~ s/\.\z//;
  return $value;
}

sub value_survived {
  my ($col, $name) = @_;
  my $got = $row->get_column($col);

  is without_trailing_zeros($got), without_trailing_zeros($sent->{$col}), $name;

  note "$col: sent '$sent->{$col}', the wire returned '$got'"
    if defined $got && $got ne $sent->{$col};
}

value_survived('dec',
  'a Decimal(10, 2) round-tripped with its value intact');
value_survived('ts_ms',
  'sub-second precision survives -- which is why portable datetime maps to '
. 'DateTime64(3) rather than second-resolution DateTime');
value_survived('ts_utc',
  'a timezone carried inside the type does not shift the stored value');

# FixedString pads with zero BYTES and hands the padding back to the client.
# That is the documented reason it is opt-in and never inferred from char(N)
# (DBIO::ClickHouse::DDL/Type mapping); if it stopped being true, that whole
# paragraph -- and the decision behind it -- would need rewriting.
{
  my $fixed = $row->get_column('s_fixed');
  is length($fixed), 3,
    'FixedString(3) returns its zero-byte padding rather than trimming it';
  is substr($fixed, 0, 2), 'ab', '... with the value itself at the front';
}

# Arrays have no bind type on any MySQL-wire DBD, so they went out as literal
# SQL; what matters is that they come back as ClickHouse array text.
like $row->get_column('tags'), qr/\A\[.*'x'.*'y'.*\]\z/,
  'an Array(String) comes back as a ClickHouse array literal';
like $row->get_column('nums'), qr/\A\[.*1.*2.*3.*\]\z/,
  'an Array(Int32) likewise';

# --- column DEFAULTs actually fire -------------------------------------------

{
  my %without = %$sent;
  $without{id} = 2;
  delete @without{qw(title counter)};

  $schema->resultset('Probe')->create(\%without);

  my $defaulted = $schema->resultset('Probe')->find(2);
  ok $defaulted, 'a second probe row, written without title or counter';
  is $defaulted->get_column('title'), 'untitled',
    q{a scalar default_value deployed as DEFAULT 'untitled' and fired};
  is $defaulted->get_column('counter'), 0,
    'a SCALAR-ref default_value deployed verbatim as DEFAULT 0 and fired';
}

# --- the native JSON type ----------------------------------------------------
#
# Its own table, on purpose. Since ticket k11 a data_type of exactly 'JSON'
# renders ClickHouse's semi-structured JSON type instead of String
# (DBIO::ClickHouse::DDL/Type mapping), and that type went through beta before
# being production-ready -- older servers need an experimental setting and
# older ones still do not have it at all. Putting it in the shared fixture
# would mean one unsupported server takes every live file down with it, so it
# is asked here, alone, where a failure says exactly which decision is at risk.

{
  my $table = 'dbio_json_probe';

  my $created = eval {
    $dbh->do(sprintf
      'CREATE TABLE `%s` (`id` Int32, `doc` JSON) ENGINE = MergeTree ORDER BY (`id`)',
      $table);
    1;
  };

  ok $created,
    'the server accepts a native JSON column with no extra setting -- if it '
  . q{does not, data_type => 'JSON' cannot stay mapped to the native type}
    or diag "server said: $@";

  SKIP: {
    skip 'the server would not create a JSON column', 2 unless $created;

    $dbh->do(sprintf
      q{INSERT INTO `%s` VALUES (1, '{"a": 1, "b": "two"}')}, $table);

    my ($reported) = $dbh->selectrow_array(q{
      SELECT type FROM system.columns
      WHERE database = currentDatabase() AND table = ? AND name = 'doc'
    }, undef, $table);
    is $reported, 'JSON',
      'system.columns reports it back as JSON -- so it round-trips through the '
    . 'diff like any other type';

    my ($value) = $dbh->selectrow_array(sprintf 'SELECT `doc` FROM `%s`', $table);
    ok defined $value && length $value, 'and a document comes back over the wire';
    diag "JSON value came back as: " . ($value // '(undef)');
  }
}

done_testing;
