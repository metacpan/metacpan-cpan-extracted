#!/usr/bin/env perl
# When a String column has few distinct values that repeat across millions of
# rows -- event types, country codes, log levels, status codes, hostnames in
# a small fleet -- declaring it as LowCardinality(String) instead of plain
# String tells the encoder (and ClickHouse) to ship the data as a small
# dictionary plus per-row indices. This script measures both the wire-size
# reduction and the encoder throughput on a synthetic event stream.
#
#   perl eg/insert_with_lowcardinality.pl              # 200000 rows
#   ROWS=2000000 perl eg/insert_with_lowcardinality.pl
# (no underscore separators in env vars -- Perl's string->number coerce
#  stops at the first underscore.)

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Time::HiRes qw(time);
use ClickHouse::Encoder;

my $ROWS = $ENV{ROWS} // 200_000;

my @event_types = qw(click view scroll hover purchase cart_add cart_remove
                     login logout signup error retry);
my @countries   = qw(US GB DE FR JP CN IN BR RU CA AU MX);
my @os_versions = ('iOS 17.4', 'iOS 16.7', 'Android 14', 'Android 13',
                   'Android 12', 'macOS 14.4', 'Windows 11', 'Windows 10');

print "Generating $ROWS rows...\n";
my $t0 = time();
my @rows;
for my $i (1 .. $ROWS) {
    push @rows, [
        $i,
        $event_types[$i % @event_types],
        $countries  [$i % @countries  ],
        $os_versions[$i % @os_versions],
        time() - $i,
    ];
}
my $gen = time() - $t0;
printf "  generation: %.2fs (%.0f rows/s)\n", $gen, $ROWS / $gen;

# Plain String columns
my $plain = ClickHouse::Encoder->new(columns => [
    ['id',      'UInt64'],
    ['event',   'String'],
    ['country', 'String'],
    ['os',      'String'],
    ['stamp',   'DateTime'],
]);

# Same schema with the three low-cardinality columns wrapped
my $lc = ClickHouse::Encoder->new(columns => [
    ['id',      'UInt64'],
    ['event',   'LowCardinality(String)'],
    ['country', 'LowCardinality(String)'],
    ['os',      'LowCardinality(String)'],
    ['stamp',   'DateTime'],
]);

print "\nEncoding...\n";
$t0 = time();
my $bin_plain = $plain->encode(\@rows);
my $enc_plain = time() - $t0;

$t0 = time();
my $bin_lc = $lc->encode(\@rows);
my $enc_lc = time() - $t0;

print "\n", '=' x 60, "\n";
printf "%-20s %12s %12s %12s\n", '', 'plain', 'LC', 'ratio';
print '-' x 60, "\n";
printf "%-20s %10.3fs %10.3fs %12s\n",
    'encode time',
    $enc_plain, $enc_lc,
    sprintf('%.2fx', $enc_plain / $enc_lc);
printf "%-20s %10.0f %10.0f\n",
    'rows/sec',
    $ROWS / $enc_plain, $ROWS / $enc_lc;
printf "%-20s %10s %10s %12s\n",
    'wire bytes',
    sprintf('%.2fM', length($bin_plain) / 1024 / 1024),
    sprintf('%.2fM', length($bin_lc)    / 1024 / 1024),
    sprintf('%.0f%%', 100 * (1 - length($bin_lc) / length($bin_plain)));
print '=' x 60, "\n";

print <<'NOTE';

Interpretation:
  - LC encoding is usually slower per row because it builds a dictionary
    plus indices instead of inlining each string. The CPU cost is bounded
    (one hash lookup per row plus one varint write).
  - LC payload is dramatically smaller: the dict has K distinct entries
    (here ~12-20 each), and each row is a 1-byte index instead of a
    length-prefixed string. For event/log workloads with K << N this is
    a 5-10x size win on the wire and downstream storage.
  - On the receiving side, ClickHouse stores LC columns much more
    efficiently and queries them via dictionary indirection -- typically
    2-10x faster for filters/group-by than plain String of the same data.
NOTE
