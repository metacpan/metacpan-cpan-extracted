use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# coerce_datetimes over the time-type surface: timezone-qualified
# DateTime, DateTime64 at several precisions, Date / Date32, and
# Nullable wrappers. The conversion is UTC-only by design (CH stores
# UTC ticks); the timezone in DateTime('tz') is a display concern and
# must not shift the value.

# --- ISO mode ----------------------------------------------------------
{
    my $block = { columns => [
        { name => 'dt',   type => 'DateTime',
          values => [0, 1700000000] },
        { name => 'dttz', type => "DateTime('Europe/Berlin')",
          values => [1700000000] },
        { name => 'd',    type => 'Date',
          values => [0] },
        { name => 'd32',  type => 'Date32',
          values => [0] },
        { name => 'ndt',  type => 'Nullable(DateTime)',
          values => [undef, 0] },
    ]};
    ClickHouse::Encoder->coerce_datetimes($block);
    is($block->{columns}[0]{values}[0], '1970-01-01T00:00:00Z',
       'DateTime epoch 0 -> ISO');
    is($block->{columns}[0]{values}[1], '2023-11-14T22:13:20Z',
       'DateTime 1700000000 -> ISO');
    is($block->{columns}[1]{values}[0], '2023-11-14T22:13:20Z',
       "DateTime('Europe/Berlin') still converts as UTC ticks");
    is($block->{columns}[2]{values}[0], '1970-01-01',
       'Date epoch 0 -> ISO date');
    is($block->{columns}[3]{values}[0], '1970-01-01',
       'Date32 epoch 0 -> ISO date');
    is($block->{columns}[4]{values}[0], undef,
       'Nullable(DateTime) undef passes through');
    is($block->{columns}[4]{values}[1], '1970-01-01T00:00:00Z',
       'Nullable(DateTime) defined value converts');
}

# --- DateTime64 precision ---------------------------------------------
{
    # 1700000000.123 at precision 3, .123456 at precision 6,
    # .123456789 at precision 9 -- the fractional digit count must
    # equal the declared precision exactly.
    my $block = { columns => [
        { name => 'p3', type => 'DateTime64(3)',
          values => [1700000000123] },
        { name => 'p6', type => "DateTime64(6, 'UTC')",
          values => [1700000000123456] },
        { name => 'p9', type => 'DateTime64(9)',
          values => [1700000000123456789] },
        { name => 'p0', type => 'DateTime64(0)',
          values => [1700000000] },
    ]};
    ClickHouse::Encoder->coerce_datetimes($block);
    is($block->{columns}[0]{values}[0], '2023-11-14T22:13:20.123Z',
       'DateTime64(3): 3 fractional digits');
    is($block->{columns}[1]{values}[0], '2023-11-14T22:13:20.123456Z',
       'DateTime64(6) with tz: 6 fractional digits');
    is($block->{columns}[2]{values}[0], '2023-11-14T22:13:20.123456789Z',
       'DateTime64(9): 9 fractional digits');
    is($block->{columns}[3]{values}[0], '2023-11-14T22:13:20Z',
       'DateTime64(0): no fractional part');
}

# --- negative DateTime64 tick (pre-epoch) -----------------------------
{
    # -500 ticks at precision 3 = -0.5s => 1969-12-31T23:59:59.500Z.
    my $block = { columns => [
        { name => 'p3', type => 'DateTime64(3)', values => [-500] },
    ]};
    ClickHouse::Encoder->coerce_datetimes($block);
    is($block->{columns}[0]{values}[0], '1969-12-31T23:59:59.500Z',
       'negative DateTime64 tick normalises fractional part');
}

# --- datetime mode (Time::Moment) -------------------------------------
SKIP: {
    eval { require Time::Moment; 1 }
        or skip 'Time::Moment not installed', 3;
    my $block = { columns => [
        { name => 'dt',   type => 'DateTime',      values => [1700000000] },
        { name => 'p3',   type => 'DateTime64(3)', values => [1700000000123] },
        { name => 'd',    type => 'Date',          values => [0] },
    ]};
    ClickHouse::Encoder->coerce_datetimes($block, as => 'datetime');
    isa_ok($block->{columns}[0]{values}[0], 'Time::Moment',
           'DateTime -> Time::Moment');
    is($block->{columns}[0]{values}[0]->epoch, 1700000000,
       'Time::Moment epoch preserved');
    is($block->{columns}[1]{values}[0]->millisecond, 123,
       'DateTime64(3) -> Time::Moment carries the milliseconds');
}

# --- skipped columns and non-time columns are untouched ---------------
{
    my $block = { columns => [
        { name => 's',  type => 'String', values => ['a', 'b'] },
        { name => 'dt', type => 'DateTime', values => [0], skipped => 1 },
    ]};
    ClickHouse::Encoder->coerce_datetimes($block);
    is_deeply($block->{columns}[0]{values}, ['a', 'b'],
              'String column left alone');
    is($block->{columns}[1]{values}[0], 0,
       'skipped column not coerced');
}

# --- bad 'as' value croaks --------------------------------------------
{
    local $@;
    eval { ClickHouse::Encoder->coerce_datetimes(
        { columns => [] }, as => 'bogus') };
    like($@, qr/'as' must be 'iso' or 'datetime'/, 'invalid as croaks');
}

done_testing();
