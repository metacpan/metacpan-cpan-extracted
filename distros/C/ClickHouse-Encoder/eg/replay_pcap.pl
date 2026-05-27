#!/usr/bin/env perl
# Replay a captured ClickHouse Native byte stream (e.g. from tcpdump
# -> tshark extraction of the HTTP body, or a saved curl
# `--output` of a `select ... format native` response) and print a
# block-by-block summary. Useful for debugging production wire
# dumps without re-running the query.
#
# Usage:
#     curl 'http://db:8123/?query=select+*+from+t+format+native' > out.bin
#     perl eg/replay_pcap.pl out.bin

use strict;
use warnings;
use ClickHouse::Encoder;

@ARGV or die "Usage: $0 <native-byte-stream-file>\n";
my $path = shift;
open my $fh, '<:raw', $path or die "open $path: $!";
local $/;
my $bytes = <$fh>;
close $fh;

my $blocks = 0;
my $rows   = 0;
my %types_seen;
ClickHouse::Encoder->decode_blocks($bytes, sub {
    my $blk = shift;
    $blocks++;
    $rows += $blk->{nrows};

    if ($blocks <= 3) {
        # Print the first three blocks in detail; just totals after.
        printf "block %d: ncols=%d nrows=%d\n",
               $blocks, $blk->{ncols}, $blk->{nrows};
        for my $col (@{ $blk->{columns} }) {
            printf "    %-20s %s\n", $col->{name}, $col->{type};
            $types_seen{$col->{type}}++;
        }
    } else {
        $types_seen{$_->{type}}++ for @{ $blk->{columns} };
    }
});

print "\n";
printf "Summary: %d blocks, %d rows total\n", $blocks, $rows;
print "Types seen across all blocks:\n";
for my $t (sort keys %types_seen) {
    printf "    %-30s x %d\n", $t, $types_seen{$t};
}
