#!/usr/bin/env perl
# Pre-aggregate a high-rate event stream in Perl, then insert the
# rolled-up counters into ClickHouse. This is the production pattern
# for ingesting metrics where the firehose is too high-cardinality to
# store as raw rows: aggregate per (key, time-bucket), then flush.
#
# Reads NDJSON events of the form:
#     {"t": <unix_seconds>, "key": "<bucket>", "n": <count>}
# from STDIN, buckets them per minute, and flushes a Native block of
# (minute, key, total_count) to ClickHouse every FLUSH_SECS wall-clock
# seconds (default 30) -- so memory stays bounded even on a stream that
# never ends.
#
# Schema:
#     create table event_counts (
#         minute UInt32,
#         key    String,
#         n      UInt64
#     ) engine = SummingMergeTree() order by (minute, key);

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use HTTP::Tiny;
use JSON::PP;
use Time::HiRes qw(time);

my $port       = $ENV{CH_PORT}   // 8123;
my $flush_secs = $ENV{FLUSH_SECS} // 30;
my $table      = $ENV{TABLE}     // 'event_counts';

my $enc = ClickHouse::Encoder->new(columns => [
    ['minute', 'UInt32'],
    ['key',    'String'],
    ['n',      'UInt64'],
]);

my $json   = JSON::PP->new->utf8;
my $http   = HTTP::Tiny->new(timeout => 30);
my $url    = "http://localhost:$port/?query="
           . _esc("insert into $table format native");

my %counters;          # { "$minute\t$key" => total_count }
my $last_flush = time();

while (defined(my $line = <>)) {
    chomp $line;
    next if $line =~ /\A\s*\z/;
    my $r = eval { $json->decode($line) };
    next if $@;

    my $minute = int(($r->{t} // time()) / 60);
    my $key    = $r->{key} // '';
    my $n      = $r->{n}   // 1;

    $counters{"$minute\t$key"} += $n;

    if (time() - $last_flush > $flush_secs) {
        flush();
        $last_flush = time();
    }
}
flush();

sub flush {
    return unless %counters;

    # Build a row arrayref from the in-memory counter map.
    my @rows;
    while (my ($k, $cnt) = each %counters) {
        my ($minute, $key) = split /\t/, $k, 2;
        push @rows, [$minute + 0, $key, $cnt];
    }

    my $bin  = $enc->encode(\@rows);
    my $resp = $http->post($url, {
        content => $bin,
        headers => { 'Content-Type' => 'application/octet-stream' },
    });
    die "insert failed (status $resp->{status}): $resp->{content}"
        unless $resp->{success};

    printf STDERR "[flush] %d aggregated rows (%.1f KB on the wire)\n",
        scalar @rows, length($bin) / 1024;
    %counters = ();
}

sub _esc {
    (my $s = $_[0]) =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
}
