#!/usr/bin/env perl
# Project a small subset of columns out of a wide select - decode
# only the columns we care about; the rest have their wire bytes
# consumed (so the cursor stays aligned) but are not materialized
# into SVs. Memory stays bounded by the kept-columns subset.
#
# Usage:
#     perl eg/json_path_projection.pl \
#         --host=db --port=8123 \
#         --table=events \
#         --keep=id,event_type
#
# Pin: the response is a Native stream; we walk it via select_blocks
# with `keep`, demonstrating that the projection is honored across
# every block.

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my $host = '127.0.0.1';
my $port = 8123;
my $tbl  = 'events';
my $keep_csv = 'id';
my $limit = 10;
GetOptions(
    'host=s'  => \$host,
    'port=i'  => \$port,
    'table=s' => \$tbl,
    'keep=s'  => \$keep_csv,
    'limit=i' => \$limit,
) or die "bad options\n";

my $keep = { map { $_ => 1 } split /,/, $keep_csv };

my $rows_emitted = 0;
ClickHouse::Encoder->select_blocks(
    "select * from $tbl limit $limit",
    host => $host, port => $port,
    keep => $keep,
    on_block => sub {
        my $blk = shift;
        for my $r (0 .. $blk->{nrows} - 1) {
            my %row;
            for my $col (@{ $blk->{columns} }) {
                next if $col->{skipped};
                $row{$col->{name}} = $col->{values}[$r];
            }
            # Print a one-line summary of the kept fields per row.
            print join(' | ',
                map { "$_=" . ($row{$_} // 'NULL') } sort keys %row), "\n";
            $rows_emitted++;
        }
    },
);

warn "# kept columns @{[ sort keys %$keep ]} across $rows_emitted rows\n";
