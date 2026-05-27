#!/usr/bin/env perl
# json_streaming.pl - read NDJSON from stdin, encode into a JSON column,
# stream to ClickHouse via insert format native in batches.
#
# Usage:
#   echo '{"event":"click","ts":1}' | json_streaming.pl --table events --col j
#
# Requirements:
#   - Cpanel::JSON::XS or JSON::PP for parsing input lines
#   - HTTP::Tiny for POSTing to ClickHouse
#   - A table created beforehand with a single JSON column, e.g.:
#       create table events (j JSON) engine=MergeTree order by tuple()
#         settings allow_experimental_json_type=1
use strict;
use warnings;
use Getopt::Long;
use HTTP::Tiny;
use ClickHouse::Encoder;

# Prefer the XS parser; fall back to core JSON::PP.
my $decode_json = do {
    if (eval { require Cpanel::JSON::XS; 1 }) {
        my $j = Cpanel::JSON::XS->new->utf8;
        sub { $j->decode($_[0]) };
    } else {
        require JSON::PP;
        my $j = JSON::PP->new->utf8;
        sub { $j->decode($_[0]) };
    }
};

my $host  = '127.0.0.1';
my $port  = 8123;
my $table = 'events';
my $col   = 'j';
my $batch = 1000;
GetOptions(
    'host=s'  => \$host,
    'port=i'  => \$port,
    'table=s' => \$table,
    'col=s'   => \$col,
    'batch=i' => \$batch,
) or die "bad options\n";

# Reject anything that could inject SQL through the --query string.
$table =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?\z/
    or die "Bad --table '$table': expected [db.]name\n";
$col =~ /\A[A-Za-z_]\w*\z/
    or die "Bad --col '$col': expected identifier\n";

my $enc = ClickHouse::Encoder->new(columns => [[$col, 'JSON']]);
my $http = HTTP::Tiny->new(timeout => 60);
my $url  = "http://$host:$port/?query="
         . "insert+into+$table+format+native&enable_json_type=1";

my $writer = sub {
    my $body = shift;
    my $resp = $http->post($url,
        { headers => { 'Content-Type' => 'application/octet-stream' },
          content => $body });
    die "insert failed (status $resp->{status}): $resp->{content}\n"
        unless $resp->{success};
};

my $streamer = $enc->streamer($writer, batch_size => $batch);
my ($n_rows, $n_batches) = (0, 0);
while (my $line = <STDIN>) {
    chomp $line;
    next if $line eq '';
    my $obj = $decode_json->($line);
    ref $obj eq 'HASH'
        or die "Line $.: top-level value must be a JSON object\n";
    $streamer->push_row([$obj]);
    $n_rows++;
    $n_batches++ if $n_rows % $batch == 0;
}
$streamer->finish;
print STDERR "Inserted $n_rows rows in approximately ",
             1 + $n_batches, " batches\n";
