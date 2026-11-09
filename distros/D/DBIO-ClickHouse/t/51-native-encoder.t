use strict;
use warnings;
use Test::More;

# t/51-native-encoder.t — the same bridge as t/50-native.t, but run through a
# real ClickHouse::Encoder and decoded again. Still no server: encode/decode
# are pure XS, so the whole round trip happens in this process.
#
# This file is an EXTRA, gated on optional modules, and the suite's claims do
# not depend on it — t/50-native.t proves the structures are right and proves
# ClickHouse::Encoder is not a dependency. What this one adds is the thing a
# structural comparison cannot: that the structures are right *about the
# encoder*. Two claims in particular, both of which the bridge's POD makes and
# neither of which is self-evident:
#
#   1. Every type DBIO::ClickHouse::DDL renders is a type the encoder parses.
#      The type strings are generated from schema metadata and only ever
#      compared against hand-written expectations; a type that ClickHouse
#      accepts in a CREATE TABLE but the encoder cannot parse would sail
#      through every other test in this distribution.
#   2. DBIO's deflated temporal form — the 'YYYY-MM-DD HH:MM:SS' string the
#      storage's datetime parser produces — is a form the encoder reads
#      correctly. The bridge does no value conversion of its own precisely
#      because it does not have to; that is a claim about someone else's
#      parser, so it is measured here rather than asserted.

BEGIN {
  eval { require ClickHouse::Encoder; 1 }
    or plan skip_all => 'ClickHouse::Encoder not installed (optional)';
  eval { require DateTime; require DateTime::Format::MySQL; 1 }
    or plan skip_all => 'DateTime / DateTime::Format::MySQL not installed (optional)';
}

use DBIO::ClickHouse::Native;

{
  package My::NativeEnc::Event;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table('native_enc_event');
  __PACKAGE__->add_columns(
    id    => { data_type => 'uuid',     is_nullable => 0 },
    kind  => { data_type => 'varchar',  size => 32, is_nullable => 0,
               extra => { low_cardinality => 1 } },
    hits  => { data_type => 'bigint',   is_nullable => 0,
               extra => { unsigned => 1 } },
    score => { data_type => 'double precision', is_nullable => 1 },
    price => { data_type => 'decimal',  size => [10, 2], is_nullable => 0 },
    ok    => { data_type => 'boolean',  is_nullable => 0 },
    grade => { data_type => 'enum',     is_nullable => 0,
               extra => { list => [qw(low high)] } },
    day   => { data_type => 'date',     is_nullable => 0 },
    ts    => { data_type => 'datetime', is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key('id');

  package My::NativeEnc::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';
  # A schema always declares its driver (core ADR 0067); a MySQL-wire DSN
  # alone names a DBD, never ClickHouse.
  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Event => 'My::NativeEnc::Event');
}

# A real MySQL-wire DSN so InflateColumn::DateTime picks up the ClickHouse
# storage's datetime parser. ->connect is lazy, so nothing is dialled.
my $schema = My::NativeEnc::Schema->connect(
  'dbi:MariaDB:database=default;host=127.0.0.1;port=9004');
my $cols = DBIO::ClickHouse::Native->columns_for($schema->source('Event'));

is_deeply $cols, [
  ['id',    'UUID'],
  ['kind',  'LowCardinality(String)'],
  ['hits',  'UInt64'],
  ['score', 'Nullable(Float64)'],
  ['price', 'Decimal(10, 2)'],
  ['ok',    'Bool'],
  ['grade', q{Enum8('low' = 1, 'high' = 2)}],
  ['day',   'Date32'],
  ['ts',    'DateTime64(3)']
], 'the column list under test covers every wrapper and parameterized form';

# --- claim 1: the encoder parses every type this distribution renders -------

my $enc;
my $built = eval { $enc = ClickHouse::Encoder->new(columns => $cols); 1 };
ok $built, 'ClickHouse::Encoder->new accepts the whole column list'
  or diag "constructor failed: $@";
BAIL_OUT('cannot continue without an encoder') unless $built;

is_deeply $enc->columns, $cols,
  'the encoder reads the types back exactly as rendered — no renormalization, '
  . 'so what DBIO deploys and what the encoder writes are the same type';

# --- claim 2: DBIO's deflated values encode to the right bytes --------------

# UTC, so the expectation below is a plain arithmetic fact rather than a
# property of the machine's zone.
my $dt = DateTime->new(year => 2026, month => 8, day => 11,
  hour => 12, minute => 0, second => 0, time_zone => 'UTC');

my $row = $schema->resultset('Event')->new_result({
  id    => '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
  kind  => 'click',
  hits  => 9_000_000_000,
  score => undef,
  price => '1234.56',
  ok    => 1,
  grade => 'high',
  day   => DateTime->new(year => 1912, month => 6, day => 23, time_zone => 'UTC'),
  ts    => $dt
});

my $rows = DBIO::ClickHouse::Native->rows_from([$row], $cols);

# What DBIO handed over: strings, because that is what deflation produces and
# what the MySQL wire returns. The bridge converted nothing.
is $rows->[0][8], '2026-08-11 12:00:00',
  'the datetime arrived as the storage-deflated string, not as an object';
is $rows->[0][7], '1912-06-23', 'the date likewise';

my $decoded = ClickHouse::Encoder->decode_blocks($enc->encode($rows));
is scalar @$decoded, 1, 'one block';
is $decoded->[0]{nrows}, 1, 'one row';

my %got = map { $_->{name} => $_->{values}[0] } @{ $decoded->[0]{columns} };

is $got{id}, '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'UUID round-trips';
is $got{kind}, 'click', 'LowCardinality(String) round-trips';
is $got{hits}, 9_000_000_000, 'UInt64 keeps a value past the 32-bit range';
is $got{score}, undef, 'Nullable(Float64) carries the NULL';
ok $got{ok}, 'Bool round-trips';

# The decoder hands a Decimal back as its unscaled integer, so 1234.56 at
# scale 2 is 123456. That is the encoder's representation, not a conversion
# this bridge made.
is $got{price}, 123456, 'Decimal(10, 2) encoded to the right unscaled integer';

# The enum decodes to its ordinal rather than its name, which makes this a
# sharper assertion than a name round-trip: it pins DBIO::ClickHouse::DDL's
# "members are numbered 1..N in declaration order" against the encoder's own
# parse of the Enum8(...) string that DDL rendered. Renumber the members and
# this fails, which is the point — renumbering is a destructive ALTER.
is $got{grade}, 2, q{'high' encoded as ordinal 2, DDL's declaration order};

# The two that matter: a string DBIO produced, read by someone else's parser.
is $got{ts}, $dt->epoch * 1000,
  'DateTime64(3) decoded to the right millisecond tick count — the encoder '
  . "parsed DBIO's deflated 'YYYY-MM-DD HH:MM:SS' with no fractional part";
is $got{day}, -21011,
  'Date32 decoded to the right (negative) day count — 1912-06-23 predates the '
  . 'epoch, which is exactly why the DDL maps date to Date32 and not Date';

# --- why "the bridge converts nothing" is load-bearing, not just tidy -------
#
# ClickHouse::Encoder parses a Decimal *string* digit by digit and scales it
# exactly; a Decimal *number* goes through a double and is lossy past 2^53. A
# DECIMAL column comes back from the DBD as a string and this bridge passes it
# through untouched, so DBIO exports land on the exact path. A bridge that
# "helpfully" numified values — or a caller that does — silently loses digits.

my $exact = ClickHouse::Encoder->new(columns => [['d', 'Decimal(18, 6)']]);
my $as_string = '123456789012.345678';
my $numified  = '123456789012.345678';
my $ignored   = $numified + 0;   # sets the SV's numeric slot

sub unscaled {
  my ($v) = @_;
  return ClickHouse::Encoder->decode_blocks($exact->encode([[$v]]))
    ->[0]{columns}[0]{values}[0];
}

is unscaled($as_string), '123456789012345678',
  'a Decimal handed over as the string DBIO produced keeps every digit';
isnt unscaled($numified), '123456789012345678',
  'the same value numified first does not — which is why nothing here '
  . 'touches the value on its way to the encoder';

done_testing;
