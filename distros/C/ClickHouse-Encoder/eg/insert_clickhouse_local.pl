#!/usr/bin/env perl
# Server-less ETL: encode rows in Perl, pipe Native bytes into clickhouse-local,
# and have it materialise a Parquet (or any output-format) file. Useful for
# offline dataset preparation without a running ClickHouse server.
#
#   perl eg/insert_clickhouse_local.pl out.parquet
#   perl eg/insert_clickhouse_local.pl out.orc Parquet ORC      (custom format)
#
# clickhouse-local reads our buffer as a typed table via --structure, then
# the select INTO OUTFILE writes the chosen format.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $out_path = shift // 'out.parquet';
my $format   = shift // 'Parquet';

my $enc = ClickHouse::Encoder->new(columns => [
    ['id',     'UInt64'],
    ['user',   'String'],
    ['score',  'Float64'],
    ['stamp',  'DateTime'],
    ['tags',   'Array(String)'],
]);

my @rows;
for my $i (1 .. 10_000) {
    push @rows, [
        $i,
        "user_$i",
        rand() * 100,
        time() - $i,
        ["batch", "row$i"],
    ];
}
my $body = $enc->encode(\@rows);
printf "Encoded %d rows to Native = %.2f MB\n",
    scalar @rows, length($body) / 1024 / 1024;

my $structure =
    'id UInt64, user String, score Float64, stamp DateTime, tags Array(String)';

# ClickHouse's insert into FUNCTION file('...', '$format') turns its source
# table into the chosen output format. The source table here is the implicit
# 'table' that --input-format Native + --structure produces from stdin.
my $query = "insert into FUNCTION file('$out_path', '$format') "
          . "select * from table";

open my $fh, '|-', 'clickhouse-local',
    '--structure',    $structure,
    '--input-format', 'Native',
    '--query',        $query
    or die "clickhouse-local: $!";
binmode $fh;
print $fh $body;
close $fh
    or die "clickhouse-local exited with code " . ($? >> 8) . "\n";

my $size = -s $out_path;
printf "Wrote $out_path (%s, %.2f KB)\n", $format, $size / 1024;
