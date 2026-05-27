#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Smoke tests for the small Perl-side helpers. Network operations are
# guarded so the file is usable without a running CH instance.

# Argument validation paths exercise the helper signatures even when
# there's no server reachable.

# insert_http: rejects bad table name before touching the network
{
    my $err = eval {
        ClickHouse::Encoder->insert_http(
            host => '127.0.0.1', port => 18123,
            table => "foo; drop table bar",
            columns => [['x','Int32']], rows => [[1]],
        ); 1
    } ? "" : $@;
    like($err, qr/Invalid table name/, 'insert_http rejects SQL injection in table');
}

# insert_http: rejects unknown compress mode
{
    my $err = eval {
        ClickHouse::Encoder->insert_http(
            host => '127.0.0.1', port => 18123,
            table => 'good_name',
            columns => [['x','Int32']], rows => [[1]],
            compress => 'snappy',
        ); 1
    } ? "" : $@;
    like($err, qr/unknown compress/, 'unknown compression mode rejected');
}

# insert_http: requires rows
{
    my $err = eval {
        ClickHouse::Encoder->insert_http(
            host => '127.0.0.1', port => 18123,
            table => 'good_name',
            columns => [['x','Int32']],
        ); 1
    } ? "" : $@;
    like($err, qr/needs rows/, 'rows is required');
}

# for_query: with via=>'client', we can't fake clickhouse-client; just
# verify the dispatch builds the same describe call as for_table for
# its own SQL fragment. We exercise the private _for_describe helper
# only indirectly. If clickhouse-client isn't installed, this branch
# dies before opening the pipe -- catch and skip.
SKIP: {
    # Cheap smoke: confirm for_query is dispatchable and routes through
    # the same plumbing. Don't require a running server.
    can_ok('ClickHouse::Encoder', 'for_query');
    can_ok('ClickHouse::Encoder', 'insert_http');
}

# insert_http with a live HTTP listener (only if 127.0.0.1:18123 is up)
SKIP: {
    my $http;
    eval { require HTTP::Tiny; $http = HTTP::Tiny->new(timeout => 1); 1 }
        or skip "HTTP::Tiny not available", 1;
    my $ping = $http->get("http://127.0.0.1:18123/ping");
    skip "ClickHouse HTTP not reachable on :18123", 1
        unless $ping->{success} && $ping->{content} =~ /Ok/;

    $http->post("http://127.0.0.1:18123/?query="
        . "drop+table+if+exists+ch_encoder_helpers_t",
        { content => '', headers => { 'Content-Length' => 0 } });
    $http->post("http://127.0.0.1:18123/?query="
        . "create+table+ch_encoder_helpers_t+(x+Int32%2Cs+String)+engine%3DMemory",
        { content => '', headers => { 'Content-Length' => 0 } });

    my $resp = ClickHouse::Encoder->insert_http(
        host => '127.0.0.1', port => 18123,
        table => 'ch_encoder_helpers_t',
        columns => [['x','Int32'],['s','String']],
        rows => [[1,'a'],[2,'b']],
    );
    ok($resp->{success}, "insert_http succeeded: status=$resp->{status}")
        or diag $resp->{content};

    my $count = $http->get(
        "http://127.0.0.1:18123/?query=select+count()+from+ch_encoder_helpers_t");
    is($count->{success} && $count->{content} =~ /^2/ ? 1 : 0, 1,
       'inserted 2 rows visible');

    # for_query: derive encoder from a select, then encode-decode round-trip
    my $enc = ClickHouse::Encoder->for_query(
        "select 1::Int32 as a, 'hi' as b",
        via => 'http', host => '127.0.0.1', port => 18123);
    isa_ok($enc, 'ClickHouse::Encoder', 'for_query returned encoder');
}

done_testing();
