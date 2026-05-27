#!/usr/bin/env perl
# CH-to-CH migration with a row-level transform between read and
# write. The source schema is discovered via for_table, the target
# encoder mirrors it (or you can override with --target-columns),
# and the transform coderef gets a chance to mutate every row
# between decode and re-encode. Useful for column renames,
# type coercions, or dropping rows.
#
# Usage:
#     perl eg/migrate_with_transform.pl \
#         --src-host=src.db --src-port=8123 \
#         --dst-host=dst.db --dst-port=8123 \
#         --src-table=events_old --dst-table=events_new

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my ($src_host, $src_port, $src_tbl) = ('127.0.0.1', 8123, 'src_t');
my ($dst_host, $dst_port, $dst_tbl) = ('127.0.0.1', 8123, 'dst_t');
my $batch_size = 5000;
GetOptions(
    'src-host=s'   => \$src_host,
    'src-port=i'   => \$src_port,
    'src-table=s'  => \$src_tbl,
    'dst-host=s'   => \$dst_host,
    'dst-port=i'   => \$dst_port,
    'dst-table=s'  => \$dst_tbl,
    'batch-size=i' => \$batch_size,
) or die "bad options\n";

# Discover the source schema. Tweak the column list here to point
# at the destination's shape if it diverges (rename / type change).
my $src_enc = ClickHouse::Encoder->for_table($src_tbl,
    via => 'http', host => $src_host, port => $src_port);
my @columns = @{ $src_enc->columns };

# Per-row transform: receives a row (arrayref aligned with @columns)
# and returns either a modified row (or the same one) to forward, or
# undef to drop the row. Customize this for the actual migration.
my $transform = sub {
    my $row = shift;
    # Example: drop rows where the first column is NULL; uppercase a
    # known string column at index 1.
    return undef if !defined $row->[0];
    $row->[1] = uc($row->[1]) if defined $row->[1];
    return $row;
};

# Long-lived sink: bulk_inserter pools an HTTP::Tiny with keep-alive
# and auto-flushes at batch_size.
my $bi = ClickHouse::Encoder->bulk_inserter(
    host       => $dst_host, port => $dst_port,
    table      => $dst_tbl,
    columns    => \@columns,
    batch_size => $batch_size,
    retries    => 3,
);

my $copied = 0;
my $dropped = 0;
ClickHouse::Encoder->select_blocks(
    "select * from $src_tbl",
    host => $src_host, port => $src_port,
    on_block => sub {
        my $blk = shift;
        for my $r (0 .. $blk->{nrows} - 1) {
            my @row = map $_->{values}[$r], @{ $blk->{columns} };
            my $out = $transform->(\@row);
            if (defined $out) {
                $bi->push($out);
                $copied++;
            } else {
                $dropped++;
            }
        }
    },
);
my $info = $bi->finish;
warn "# copied $copied rows ($dropped dropped) in "
   . "$info->{batches} batches\n";
