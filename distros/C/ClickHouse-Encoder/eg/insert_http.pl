#!/usr/bin/env perl
# End-to-end example: encode rows and insert them via the ClickHouse HTTP API.
#
# Run a local ClickHouse with HTTP on the default port 8123, then:
#   perl eg/insert_http.pl
#
# This is the simplest way to actually use the encoder — the binary buffer it
# returns is the raw body for an `insert ... format native` request.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use HTTP::Tiny;
use URI::Escape qw(uri_escape);
use ClickHouse::Encoder;

my $base = $ENV{CH_HTTP} // 'http://localhost:8123';
my $http = HTTP::Tiny->new(timeout => 10);

sub run_query {
    my ($sql, %opt) = @_;
    # POST for everything: ClickHouse rejects modifying queries via GET.
    my $url  = "$base/?query=" . uri_escape($sql);
    my $resp = $http->post($url, {
        content => $opt{body} // '',
        headers => { 'content-type' => 'application/octet-stream' },
    });
    die "ClickHouse query failed (status $resp->{status}): $resp->{content}\n"
        unless $resp->{success};
    return $resp->{content};
}

run_query('drop table if exists demo_events');
run_query(<<'SQL');
create table demo_events (
    id        UInt64,
    user      String,
    tags      Array(String),
    coords    Tuple(Float64, Float64),
    score     Nullable(Float64),
    occurred  DateTime
) engine = MergeTree order by id
SQL

my $enc = ClickHouse::Encoder->new(columns => [
    ['id',       'UInt64'],
    ['user',     'String'],
    ['tags',     'Array(String)'],
    ['coords',   'Tuple(Float64, Float64)'],
    ['score',    'Nullable(Float64)'],
    ['occurred', 'DateTime'],
]);

my @rows;
for my $i (1 .. 1000) {
    push @rows, [
        $i,
        "user_$i",
        ['perl', 'clickhouse', "tag$i"],
        [55.7 + rand(), 37.6 + rand()],
        ($i % 7 == 0) ? undef : rand(100),
        time() - $i,
    ];
}

my $body = $enc->encode(\@rows);
printf "Encoded %d rows = %d bytes\n", scalar @rows, length $body;

run_query('insert into demo_events format native', body => $body);

my $count = run_query('select count() from demo_events format tabseparated');
chomp $count;
print "Server reports: $count rows\n";

# Also fetch a sample
print "\nSample rows:\n";
print run_query('select id, user, tags, coords, score, occurred from demo_events order by id limit 3 format PrettyCompact');

run_query('drop table demo_events');
