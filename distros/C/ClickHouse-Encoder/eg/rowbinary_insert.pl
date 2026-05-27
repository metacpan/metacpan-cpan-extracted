#!/usr/bin/env perl
# Insert via the RowBinary format instead of Native. Native is the
# preferred path (see eg/insert_http.pl); RowBinary is shown here for
# interop with pipelines that already speak it. encode_row_binary
# produces the body; the URL just asks for `format RowBinary`.
#
# Usage:
#     perl eg/rowbinary_insert.pl --host=db --port=8123 --table=events

use strict;
use warnings;
use Getopt::Long;
use HTTP::Tiny;
use ClickHouse::Encoder;

my ($host, $port, $table) = ('127.0.0.1', 8123, 'events');
GetOptions('host=s' => \$host, 'port=i' => \$port, 'table=s' => \$table)
    or die "bad options\n";

my $enc = ClickHouse::Encoder->new(columns => [
    ['id',   'UInt64'],
    ['name', 'String'],
    ['tags', 'Array(String)'],
    ['score', 'Nullable(Float64)'],
]);

my @rows = (
    [1, 'alice', ['perl', 'db'], 0.95],
    [2, 'bob',   [],             undef],
);

my $body = $enc->encode_row_binary(\@rows);

my $url  = "http://$host:$port/?query="
         . "insert%20into%20$table%20format%20RowBinary";
my $resp = HTTP::Tiny->new(timeout => 30)->post(
    $url, { content => $body,
            headers => { 'Content-Type' => 'application/octet-stream' } });

die "insert failed (status $resp->{status}): $resp->{content}\n"
    unless $resp->{success};
print "inserted ", scalar(@rows), " rows via RowBinary\n";

# Round-trip check: a RowBinary body decodes back with the same encoder.
my $back = $enc->decode_row_binary($body);
print "local decode recovered ", scalar(@$back), " rows\n";
