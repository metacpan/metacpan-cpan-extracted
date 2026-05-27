#!/usr/bin/env perl
# Replicate one ClickHouse table to another (potentially on a different
# server) by streaming Native bytes end-to-end -- no Perl-side row
# decode at all. The encoder isn't strictly needed here since both
# sides speak Native, but for_table() validates the destination schema
# and the script demonstrates the streaming pipe pattern users build
# their own variants on (filtering, transforms, etc.).
#
# This is the "free" case: source select format native, destination
# insert format native, identical schemas. With matching schemas the
# server-side codepath is a copy through the column ColumnPtr layer,
# which is the fastest cluster-reshard primitive ClickHouse offers.
#
# Usage:
#     CH_SRC=src.example:8123 CH_DST=dst.example:8123 \
#     perl eg/clickhouse_replication.pl src.events dst.events
#
#     # With a where clause:
#     SQL_FILTER="dt >= today() - 7" perl eg/clickhouse_replication.pl ...

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use HTTP::Tiny;
use File::Temp qw(tempfile);

my ($src_table, $dst_table) = @ARGV;
die "Usage: $0 <src_table> <dst_table>\n" unless $src_table && $dst_table;

my $src_endpoint = $ENV{CH_SRC} // 'localhost:8123';
my $dst_endpoint = $ENV{CH_DST} // 'localhost:8123';
my $src_url = "http://$src_endpoint/";
my $dst_url = "http://$dst_endpoint/";
my $where   = $ENV{SQL_FILTER};

my ($dst_host, $dst_port) = split /:/, $dst_endpoint, 2;
$dst_port //= 8123;

# Validate the destination schema against the actual destination server
# (not localhost). We don't use the encoder for the data path -- rows go
# server-to-server as Native bytes.
my $enc = ClickHouse::Encoder->for_table($dst_table,
    via  => 'http',
    host => $dst_host,
    port => $dst_port,
);
print STDERR "destination schema validates: ", scalar(@{ $enc->columns }),
    " columns\n";

# Pull from source as Native, spool to a temp file, post to destination.
# HTTP::Tiny is synchronous so we can't pipe one connection straight into
# the other; the temp file keeps process memory bounded by HTTP::Tiny's
# chunk buffer (Perl-side), trading bandwidth-disk-bandwidth for RAM.
# For tables that don't fit on local disk, partition the source query
# (where on a key range) and run this script per partition.
my $select = "select * from $src_table"
           . ($where ? " where $where" : '')
           . " format native";
my $insert = "insert into $dst_table format native";

my $http = HTTP::Tiny->new(timeout => 600);

my ($spool, $spool_path) = tempfile('ch-repl-XXXXXX', UNLINK => 1, TMPDIR => 1);
binmode $spool;

my $total = 0;
my $resp  = $http->get($src_url . '?query=' . _esc($select), {
    data_callback => sub {
        print $spool $_[0] or die "spool write: $!";
        $total += length $_[0];
        print STDERR "  fetched $total bytes...\r" if $total % (1024*1024) < 8192;
    },
});
die "source select failed (status $resp->{status}): $resp->{content}"
    unless $resp->{success};
close $spool or die "spool close: $!";

print STDERR "\nfetched $total bytes total, posting to destination...\n";

# Stream the spool back to the destination via a content generator;
# HTTP::Tiny calls this until it returns "" (EOF).
open my $rfh, '<', $spool_path or die "open spool $spool_path: $!";
binmode $rfh;
my $resp2 = $http->post($dst_url . '?query=' . _esc($insert), {
    content => sub {
        my $buf;
        my $n = read($rfh, $buf, 64 * 1024);
        return defined $n && $n > 0 ? $buf : '';
    },
    headers => {
        'Content-Type'   => 'application/octet-stream',
        'Content-Length' => $total,
    },
});
close $rfh;
die "destination insert failed (status $resp2->{status}): $resp2->{content}"
    unless $resp2->{success};

print STDERR "ok: replicated $src_table -> $dst_table ($total bytes)\n";

sub _esc {
    (my $s = $_[0]) =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
}
