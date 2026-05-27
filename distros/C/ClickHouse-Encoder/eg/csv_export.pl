#!/usr/bin/env perl
# select -> Native -> decode -> CSV. Counterpart to eg/from_csv.pl.
# Demonstrates select_blocks driving a CSV writer with header row
# emitted from the first block's column names.
#
# Usage:
#     perl eg/csv_export.pl --host=db --port=8123 \
#         --sql='select id, event, ts from events' > out.csv

use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my ($host, $port, $sql, $sep) = ('127.0.0.1', 8123, 'select 1', ',');
GetOptions(
    'host=s'      => \$host,
    'port=i'      => \$port,
    'sql=s'       => \$sql,
    'separator=s' => \$sep,
) or die "bad options\n";

# RFC-4180-ish CSV cell escaping: quote if the cell contains the
# separator, a double quote, CR, or LF; double quotes inside a
# quoted cell are doubled.
sub csv_cell {
    my $v = shift;
    return '' unless defined $v;
    $v = "$v";   # stringify for nested refs (decoder gives scalars for these)
    if ($v =~ /[\r\n"$sep]/) {
        $v =~ s/"/""/g;
        return qq{"$v"};
    }
    return $v;
}

my $printed_header = 0;
ClickHouse::Encoder->select_blocks(
    $sql,
    host => $host, port => $port,
    on_block => sub {
        my $blk = shift;
        if (!$printed_header) {
            print join($sep, map { csv_cell($_->{name}) }
                              @{ $blk->{columns} }), "\n";
            $printed_header = 1;
        }
        for my $r (0 .. $blk->{nrows} - 1) {
            print join($sep, map { csv_cell($_->{values}[$r]) }
                              @{ $blk->{columns} }), "\n";
        }
    },
);
