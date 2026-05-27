#!/usr/bin/env perl
# End-to-end TCP-protocol insert pipeline with native-compressed Data
# packets. Demonstrates the matched pair:
#     pack_query(... compression => COMPRESSION_ENABLE)
#     pack_data(... compress => 'lz4')
#     pack_data_end(... compress => 'lz4')
#
# Targets CH protocol revision <= 54474 (older than 24.10's chunking
# negotiation; see CAVEATS in ClickHouse::Encoder::TCP). For modern
# servers (rev >= 54475) prefer HTTP - the compressed-block framing
# itself is identical, just the handshake differs.
#
# Usage:
#     perl eg/tcp_compressed_pipeline.pl --host=127.0.0.1 --port=9000

use strict;
use warnings;
use Getopt::Long;
use IO::Socket::INET;
use ClickHouse::Encoder;
use ClickHouse::Encoder::TCP;

my ($host, $port, $user, $password, $database) =
    ('127.0.0.1', 9000, 'default', '', 'default');
my $table = 'tcp_compressed_demo';
my $n_rows = 1000;
GetOptions(
    'host=s'     => \$host,
    'port=i'     => \$port,
    'user=s'     => \$user,
    'password=s' => \$password,
    'database=s' => \$database,
    'table=s'    => \$table,
    'rows=i'     => \$n_rows,
) or die "bad options\n";

my $sock = IO::Socket::INET->new(PeerAddr => "$host:$port", Timeout => 5)
    or die "connect $host:$port: $!\n";
binmode $sock;

# One buffer threaded through every read_packet call: a single
# sysread can pull in several packets, and the buffer carries the
# over-read bytes forward so none are lost between calls.
my $rbuf = '';
sub read_or_die {
    my $pkt = ClickHouse::Encoder::TCP->read_packet($sock, buffer => \$rbuf);
    die "server exception ($pkt->{name}): $pkt->{message}\n"
        if $pkt->{type} == ClickHouse::Encoder::TCP::SERVER_EXCEPTION;
    return $pkt;
}

# Handshake
print $sock ClickHouse::Encoder::TCP->pack_hello(
    user => $user, password => $password, database => $database);
my $hello = read_or_die();
die "expected Hello, got type $hello->{type}\n"
    unless $hello->{type} == ClickHouse::Encoder::TCP::SERVER_HELLO;
warn "# connected to $hello->{name} rev $hello->{revision}\n";

# Drop + create the target table
for my $sql ("drop table if exists $database.$table",
             "create table $database.$table "
           . "(id Int32, msg String, ts DateTime) engine = Memory") {
    print $sock ClickHouse::Encoder::TCP->pack_query(query => $sql);
    while (1) {
        my $p = read_or_die();
        last if $p->{type} == ClickHouse::Encoder::TCP::SERVER_END_OF_STREAM;
        next if $p->{type} == ClickHouse::Encoder::TCP::SERVER_PROGRESS
             || $p->{type} == ClickHouse::Encoder::TCP::SERVER_PROFILE_INFO
             || $p->{type} == ClickHouse::Encoder::TCP::SERVER_PROFILE_EVENTS;
    }
}

# insert with compression negotiated
print $sock ClickHouse::Encoder::TCP->pack_query(
    query       => "insert into $database.$table format native",
    compression => ClickHouse::Encoder::TCP::COMPRESSION_ENABLE,
);

# Drain server's pre-insert chatter (TableColumns, sample Data, etc.)
while (1) {
    my $p = read_or_die();
    last if $p->{type} == ClickHouse::Encoder::TCP::SERVER_DATA;
    next if $p->{type} == ClickHouse::Encoder::TCP::SERVER_TABLE_COLUMNS
         || $p->{type} == ClickHouse::Encoder::TCP::SERVER_PROGRESS;
}

# Build and send compressed Data packets
my $enc = ClickHouse::Encoder->new(columns =>
    [['id','Int32'], ['msg','String'], ['ts','DateTime']]);
my $batch_size = 250;
my $now = time();
for (my $r = 0; $r < $n_rows; $r += $batch_size) {
    my $end = $r + $batch_size > $n_rows ? $n_rows : $r + $batch_size;
    my $bytes = $enc->encode([
        map [[$_, "row-$_", $now + $_]], $r .. $end - 1
    ]);
    print $sock ClickHouse::Encoder::TCP->pack_data($bytes, compress => 'lz4');
}

# End-of-insert sentinel must also go through compressed framing once
# compression is negotiated.
print $sock ClickHouse::Encoder::TCP->pack_data_end(compress => 'lz4');

# Drain post-insert to EndOfStream
while (1) {
    my $p = read_or_die();
    last if $p->{type} == ClickHouse::Encoder::TCP::SERVER_END_OF_STREAM;
}

# Confirm count
print $sock ClickHouse::Encoder::TCP->pack_query(
    query => "select count() from $database.$table");
while (1) {
    my $p = read_or_die();
    if ($p->{type} == ClickHouse::Encoder::TCP::SERVER_DATA && $p->{block}{nrows}) {
        my $count = $p->{block}{columns}[0]{values}[0];
        warn "# inserted $count rows via compressed TCP\n";
    }
    last if $p->{type} == ClickHouse::Encoder::TCP::SERVER_END_OF_STREAM;
}
close $sock;
