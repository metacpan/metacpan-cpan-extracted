#!/usr/bin/env perl
# Surface ClickHouse server-side stats from an insert pipeline. Every
# HTTP response carries X-ClickHouse-* headers; insert_http and
# bulk_inserter parse them into a `ch` slot. bulk_inserter additionally
# rolls the X-ClickHouse-Summary counters up across batches, so a
# long-running loader can emit metrics without a separate query.
#
# Usage:
#     perl eg/observability.pl --host=db --port=8123 --table=events

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my ($host, $port, $table) = ('127.0.0.1', 8123, 'events');
GetOptions('host=s' => \$host, 'port=i' => \$port, 'table=s' => \$table)
    or die "bad options\n";

my $bi = ClickHouse::Encoder->bulk_inserter(
    host => $host, port => $port, table => $table,
    columns => [['id', 'UInt64'], ['name', 'String']],
    batch_size => 1000,
);

# Feed a few batches.
for my $batch (1 .. 5) {
    $bi->push([$_, "row-$_"]) for 1 .. 1000;
    # Per-batch detail from the most recent flush:
    if (my $last = $bi->last_response) {
        my $ch = $last->{ch} || {};
        printf "batch %d: query-id=%s written_rows=%s\n",
            $batch,
            $ch->{'query-id'}             // '?',
            ($ch->{summary} || {})->{written_rows} // '?';
    }
}
$bi->finish;

# Cumulative rollup across every batch this inserter sent.
my $summary = $bi->summary;
print "--- cumulative ---\n";
printf "  rows sent (client count): %d\n", $bi->sent_rows;
printf "  batches:                  %d\n", $bi->sent_batches;
for my $k (sort keys %$summary) {
    printf "  %-22s %s\n", $k, $summary->{$k};
}
