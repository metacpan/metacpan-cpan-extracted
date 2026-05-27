#!/usr/bin/env perl
# Streaming select via select_blocks(): runs a select against a
# ClickHouse HTTP endpoint and processes each result block as it
# arrives, never buffering the full response in memory. Pairs
# naturally with insert_streaming.pl on the write side.
#
# Usage:
#     perl eg/select_blocks_streaming.pl --host=db --port=8123 \
#         --sql='select event, count() c from events group by event' \
#         --keep=event,c

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my $host = '127.0.0.1';
my $port = 8123;
my $db   = 'default';
my $user = 'default';
my $pwd  = '';
my $sql  = 'select 1';
my $keep_csv;
my $limit = 0;
GetOptions(
    'host=s'     => \$host,
    'port=i'     => \$port,
    'database=s' => \$db,
    'user=s'     => \$user,
    'password=s' => \$pwd,
    'sql=s'      => \$sql,
    'keep=s'     => \$keep_csv,
    'limit=i'    => \$limit,        # stop after N rows (any block boundary)
) or die "bad options\n";

# Optional column projection: --keep=col1,col2 keeps only those.
my $keep = $keep_csv ? { map { $_ => 1 } split /,/, $keep_csv } : undef;

my $rows_seen   = 0;
my $blocks_seen = 0;
ClickHouse::Encoder->select_blocks(
    $sql,
    host => $host, port => $port,
    database => $db, user => $user, password => $pwd,
    keep => $keep,
    on_block => sub {
        my $blk = shift;
        $blocks_seen++;
        # Print one row per line, tab-separated, columns in declared order
        # (skipped columns are printed as -).
        for my $r (0 .. $blk->{nrows} - 1) {
            print join("\t",
                map { $_->{skipped} ? '-' : ($_->{values}[$r] // '') }
                @{ $blk->{columns} }), "\n";
            $rows_seen++;
            return if $limit && $rows_seen >= $limit;
        }
    },
);

warn "# processed $rows_seen rows across $blocks_seen blocks\n";
