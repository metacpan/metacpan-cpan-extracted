#!/usr/bin/env perl
# Streaming inserts: reuse one encoder across many batches and pipe each
# batch to clickhouse-client.
#
#   perl eg/insert_streaming.pl                # 10 batches x 10000 rows
#   ROWS=50000 BATCHES=20 perl eg/insert_streaming.pl
#
# An encoder built once with `ClickHouse::Encoder->new(...)` is reusable:
# you pay the type-parsing cost upfront and then encode many batches with the
# same column layout. Pair this with any HTTP / TCP / pipe transport.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Time::HiRes qw(time);
use ClickHouse::Encoder;

my $port    = $ENV{CH_PORT}   // 9000;
my $batches = $ENV{BATCHES}   // 10;
my $rows    = $ENV{ROWS}      // 10_000;

my @client_cmd = ('clickhouse-client', '--port', $port);

sub query {
    my $q = shift;
    system(@client_cmd, '--query', $q) == 0
        or die "Query failed ($?): $q\n";
}

query('drop table if exists demo_stream');
query(<<'SQL');
create table demo_stream (
    id        UInt64,
    user      String,
    tags      Array(String),
    score     Nullable(Float64),
    occurred  DateTime
) engine = MergeTree order by id
SQL

# Build the encoder ONCE and reuse for every batch.
my $enc = ClickHouse::Encoder->new(columns => [
    ['id',       'UInt64'],
    ['user',     'String'],
    ['tags',     'Array(String)'],
    ['score',    'Nullable(Float64)'],
    ['occurred', 'DateTime'],
]);

my $total_bytes = 0;
my $start = time();

for my $b (1 .. $batches) {
    my @rows;
    for my $i (1 .. $rows) {
        my $id = ($b - 1) * $rows + $i;
        push @rows, [
            $id,
            "user_$id",
            ['perl', 'clickhouse', "batch$b"],
            ($i % 7 == 0) ? undef : rand(100),
            time() - $i,
        ];
    }

    my $bin = $enc->encode(\@rows);
    $total_bytes += length $bin;

    open my $fh, '|-', @client_cmd, '--query', 'insert into demo_stream format native'
        or die "Cannot pipe to clickhouse-client: $!";
    binmode $fh;
    print $fh $bin;
    close $fh
        or die "clickhouse-client failed (exit code " . ($? >> 8) . ")\n";

    printf "batch %2d/%d: %d rows = %d bytes\n", $b, $batches, scalar @rows, length $bin;
}

my $elapsed = time() - $start;
my $count = `@client_cmd --query 'select count() from demo_stream'`;
chomp $count;

printf "\n%d rows in %.2fs (%.0f rows/s, %.1f MB/s)\n",
    $count, $elapsed, $count / $elapsed, $total_bytes / $elapsed / 1024 / 1024;

query('drop table demo_stream');
