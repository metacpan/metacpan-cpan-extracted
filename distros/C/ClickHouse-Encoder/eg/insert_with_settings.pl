#!/usr/bin/env perl
# insert with per-query ClickHouse settings and an idempotency token.
#
#   settings    => { ... }  - any query-level CH setting, applied as
#                             URL params (max_execution_time, memory
#                             limits, async_insert, ...).
#   dedup_token => $id      - insert_deduplication_token: re-sending an
#                             identical batch under the same token is
#                             ignored by the server, so a retry after
#                             an ambiguous network failure is safe.
#
# Usage:
#     perl eg/insert_with_settings.pl --host=db --port=8123 --table=events

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my ($host, $port, $table) = ('127.0.0.1', 8123, 'events');
GetOptions('host=s' => \$host, 'port=i' => \$port, 'table=s' => \$table)
    or die "bad options\n";

my @rows = map { [$_, "event-$_"] } 1 .. 500;

# A stable token derived from the batch identity: the same logical
# batch always carries the same token, so an at-least-once delivery
# layer cannot double-insert it.
my $batch_token = "events-batch-" . (@rows ? "$rows[0][0]-$rows[-1][0]" : 'empty');

my %common = (
    host    => $host,
    port    => $port,
    table   => $table,
    columns => [['id', 'UInt64'], ['name', 'String']],
    settings => {
        max_execution_time => 30,
        max_memory_usage   => '2000000000',   # 2 GB
    },
    dedup_token => $batch_token,
);

my $resp = ClickHouse::Encoder->insert_http(%common, rows => \@rows);
die "insert failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};
print "inserted ", scalar(@rows), " rows (token: $batch_token)\n";

# Re-sending the identical batch under the same token is a no-op
# server-side: the deduplication token makes the retry safe.
my $retry = ClickHouse::Encoder->insert_http(%common, rows => \@rows);
print "retry under same token: HTTP $retry->{status} ",
      "(server deduplicates - no rows added)\n"
    if $retry->{success};
