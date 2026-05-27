#!/usr/bin/env perl
# coerce_datetimes: post-process a decoded block to rewrite Date /
# Date32 / DateTime / DateTime64 columns from raw epoch integers into
# ISO 8601 strings or Time::Moment instances.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Encode a block with one of every time-column type, decode it, and
# coerce. 1700000000 = 2023-11-14 22:13:20 UTC; 19675 days since
# epoch = 2023-11-14 (Date column equivalent).
my @rows = (
    ['2023-11-14',          '2023-11-14',
     1700000000,
     '1700000000.123456',
    ],
    ['1970-01-01',          '1969-12-31',
     0,
     '0',
    ],
);

my $enc = ClickHouse::Encoder->new(columns => [
    ['d',   'Date'],
    ['d32', 'Date32'],
    ['dt',  'DateTime'],
    ['dt64','DateTime64(6)'],
]);
my $bytes = $enc->encode(\@rows);

# Without coercion: integer epochs
{
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    is($blk->{columns}[0]{values}[0], 19675,       'Date raw value (days)');
    is($blk->{columns}[2]{values}[0], 1700000000,  'DateTime raw value (epoch s)');
    cmp_ok($blk->{columns}[3]{values}[0], '==', 1700000000123456,
       'DateTime64(6) raw value (ticks)');
}

# Coerce to ISO 8601 strings (default)
{
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    ClickHouse::Encoder->coerce_datetimes($blk);
    is($blk->{columns}[0]{values}[0], '2023-11-14',
       'Date -> "YYYY-MM-DD"');
    is($blk->{columns}[0]{values}[1], '1970-01-01',
       'Date epoch=0 -> "1970-01-01"');
    is($blk->{columns}[1]{values}[0], '2023-11-14',
       'Date32 -> "YYYY-MM-DD"');
    is($blk->{columns}[1]{values}[1], '1969-12-31',
       'Date32 pre-epoch -> "1969-12-31"');
    is($blk->{columns}[2]{values}[0], '2023-11-14T22:13:20Z',
       'DateTime -> ISO UTC with Z suffix');
    is($blk->{columns}[2]{values}[1], '1970-01-01T00:00:00Z',
       'DateTime epoch=0 -> "1970-01-01T00:00:00Z"');
    is($blk->{columns}[3]{values}[0], '2023-11-14T22:13:20.123456Z',
       'DateTime64(6) -> 6 fractional digits');
}

# Coerce to Time::Moment (optional)
SKIP: {
    eval { require Time::Moment; 1 }
        or skip 'Time::Moment not installed', 4;
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    ClickHouse::Encoder->coerce_datetimes($blk, as => 'datetime');
    isa_ok($blk->{columns}[0]{values}[0], 'Time::Moment',
           'Date -> Time::Moment');
    isa_ok($blk->{columns}[2]{values}[0], 'Time::Moment',
           'DateTime -> Time::Moment');
    is($blk->{columns}[2]{values}[0]->epoch, 1700000000,
       'DateTime -> Time::Moment with correct epoch');
    is($blk->{columns}[3]{values}[0]->nanosecond, 123_456_000,
       'DateTime64(6) -> Time::Moment with 6-digit precision widened to ns');
}

# Bad as => value rejected
{
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    my $err = eval {
        ClickHouse::Encoder->coerce_datetimes($blk, as => 'unix'); 1
    } ? '' : $@;
    like($err, qr/'as' must be/, 'invalid as => value rejected');
}

# Non-time columns are untouched
{
    my $e2 = ClickHouse::Encoder->new(columns =>
        [['n','Int32'], ['ts','DateTime']]);
    my $bytes2 = $e2->encode([[7, 1700000000]]);
    my $blk = ClickHouse::Encoder->decode_block($bytes2);
    ClickHouse::Encoder->coerce_datetimes($blk);
    is($blk->{columns}[0]{values}[0], 7, 'Int32 column untouched');
    is($blk->{columns}[1]{values}[0], '2023-11-14T22:13:20Z',
       'DateTime column coerced');
}

# Undef values pass through unchanged
{
    my $e3 = ClickHouse::Encoder->new(columns =>
        [['ts','Nullable(DateTime)']]);
    my $bytes3 = $e3->encode([[1700000000], [undef]]);
    my $blk = ClickHouse::Encoder->decode_block($bytes3);
    ClickHouse::Encoder->coerce_datetimes($blk);
    is($blk->{columns}[0]{values}[0], '2023-11-14T22:13:20Z',
       'Nullable(DateTime) non-null coerced');
    ok(!defined $blk->{columns}[0]{values}[1],
       'Nullable(DateTime) undef preserved');
}

done_testing();
