#!/usr/bin/env perl
# migrate_table.pl - copy rows from one ClickHouse table to another over
# HTTP using Native format end-to-end. Reads the source via
# select ... format native and pipes each block through decode/encode
# into insert ... format native, so the entire pipeline stays in
# columnar binary form.
#
# Usage:
#   migrate_table.pl --src-table events --dst-table events_copy
#   migrate_table.pl --src-host db1 --dst-host db2 \
#                    --src-table events --dst-table events_copy \
#                    --where "ts >= '2026-05-01'"
#
# The schemas of src and dst must match; this script does not translate
# types. Use alter table ... modify column on the destination first if
# you need a schema change. Uses the decode_blocks callback form so
# decoded blocks don't accumulate. Note: the select response body is
# still fetched in one HTTP GET - for very large tables, slice the
# source query with where / limit or split by date range.
use strict;
use warnings;
use Getopt::Long;
use HTTP::Tiny;
use Encode;
use ClickHouse::Encoder;

my ($src_host, $src_port, $src_table) = ('127.0.0.1', 8123, '');
my ($dst_host, $dst_port, $dst_table) = ('127.0.0.1', 8123, '');
my $where      = '';
my $limit      = 0;
my $batch_size = 100_000;
my $compress   = 'raw';
GetOptions(
    'src-host=s'   => \$src_host,
    'src-port=i'   => \$src_port,
    'src-table=s'  => \$src_table,
    'dst-host=s'   => \$dst_host,
    'dst-port=i'   => \$dst_port,
    'dst-table=s'  => \$dst_table,
    'where=s'      => \$where,
    'limit=i'      => \$limit,
    'batch-size=i' => \$batch_size,
    'compress=s'   => \$compress,
) or die "bad options\n";

$src_table =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/
    or die "Bad --src-table\n";
$dst_table =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/
    or die "Bad --dst-table\n";

my $esc = sub {
    my $s = Encode::encode('UTF-8', $_[0], 0);
    $s =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
};
my $sql = "select * from $src_table"
        . ($where ne '' ? " where $where" : '')
        . ($limit > 0   ? " limit $limit" : '')
        . " format native";

my $http = HTTP::Tiny->new(timeout => 600);
my $select_url = "http://$src_host:$src_port/?query=" . $esc->($sql);
my $resp = $http->get($select_url);
die "select failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};

# Determine the destination encoder lazily from the first block's column
# headers (decode_block surfaces type strings even when we discard
# values).
my $enc;
my $bi;
my $total_rows = 0;

ClickHouse::Encoder->decode_blocks($resp->{content}, sub {
    my $block = shift;
    if (!$enc) {
        my @cols = map [$_->{name}, $_->{type}], @{ $block->{columns} };
        $enc = ClickHouse::Encoder->new(columns => \@cols);
        $bi = ClickHouse::Encoder->bulk_inserter(
            host       => $dst_host,
            port       => $dst_port,
            table      => $dst_table,
            encoder    => $enc,
            batch_size => $batch_size,
            compress   => $compress);
    }
    # Transpose column-major decoded block to row-major for the encoder.
    for my $r (0 .. $block->{nrows} - 1) {
        $bi->push([map $_->{values}[$r], @{ $block->{columns} }]);
    }
    $total_rows += $block->{nrows};
});
$bi->finish if $bi;

print STDERR "Migrated $total_rows rows from $src_table to $dst_table\n";
