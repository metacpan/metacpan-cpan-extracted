#!/usr/bin/env perl
# replay.pl - decode a captured `format native` byte stream and re-insert
# the rows into a target table. Demonstrates end-to-end decode/encode
# symmetry: the source can be a file (e.g. a curl dump) or another CH
# server.
#
# Usage:
#   curl 'http://src/?query=select+*+from+t+format+native' > snap.bin
#   replay.pl --src-file snap.bin --table t_copy
#
#   # Or pipe directly from one CH to another:
#   curl 'http://src/?query=select+*+from+t+format+native' \
#     | replay.pl --stdin --table t_copy
use strict;
use warnings;
use Getopt::Long;
use ClickHouse::Encoder;

my $src_file;
my $stdin;
my ($host, $port, $table) = ('127.0.0.1', 8123, '');
my $batch_size = 100_000;
my $compress   = 'raw';
GetOptions(
    'src-file=s'   => \$src_file,
    'stdin'        => \$stdin,
    'host=s'       => \$host,
    'port=i'       => \$port,
    'table=s'      => \$table,
    'batch-size=i' => \$batch_size,
    'compress=s'   => \$compress,
) or die "bad options\n";

die "Specify --src-file PATH or --stdin\n"
    unless $src_file || $stdin;
die "--table required\n" unless $table;
$table =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/
    or die "Bad --table\n";

my $fh;
if ($stdin) {
    $fh = \*STDIN;
} else {
    open $fh, '<', $src_file or die "open $src_file: $!";
}
binmode $fh;

my $enc;
my $bi;
my $total = 0;

ClickHouse::Encoder->decode_stream($fh, sub {
    my $block = shift;
    if (!$enc) {
        my @cols = map [$_->{name}, $_->{type}], @{ $block->{columns} };
        $enc = ClickHouse::Encoder->new(columns => \@cols);
        $bi  = ClickHouse::Encoder->bulk_inserter(
            host       => $host,
            port       => $port,
            table      => $table,
            encoder    => $enc,
            batch_size => $batch_size,
            compress   => $compress);
    }
    for my $r (0 .. $block->{nrows} - 1) {
        $bi->push([map $_->{values}[$r], @{ $block->{columns} }]);
    }
    $total += $block->{nrows};
});
close $fh;
$bi->finish if $bi;

print STDERR "Replayed $total rows into $table\n";
