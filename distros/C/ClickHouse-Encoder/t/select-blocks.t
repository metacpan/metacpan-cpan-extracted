#!/usr/bin/env perl
# select_blocks is mainly a streaming HTTP wrapper; the meaningful
# unit-test we can do without a real server is to verify the
# argument validation and SQL-format guard. The end-to-end behavior
# is exercised by t/live.t against a real ClickHouse server.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Required on_block coderef
{
    my $err = eval {
        ClickHouse::Encoder->select_blocks('select 1'); 1
    } ? '' : $@;
    like($err, qr/on_block.*required/i,
         'select_blocks croaks without on_block');
}

# Reject SQL with a trailing format clause (we always append
# default_format=Native via the URL, and a user format would shadow
# it). The mixed-case inputs below also exercise the case-insensitive
# guard.
{
    for my $sql ('select 1 format JSON', 'select 1 FORMAT TabSeparated',
                 "select 1  format  csv") {
        my $err = eval {
            ClickHouse::Encoder->select_blocks($sql,
                on_block => sub { }); 1
        } ? '' : $@;
        like($err, qr/format clause/, "rejects '$sql'");
    }
}

# Option-stripping: select_blocks drops keys it consumes (on_block,
# keep, timeout, decompress) and dedup_token (INSERT-only, undocumented
# on SELECT) before forwarding to _http_url_headers. Capture by
# monkey-patching HTTP::Tiny->post so we can inspect the URL it sees.
{
    require HTTP::Tiny;
    my @seen;
    # 'once' too: the typeglob is mentioned a single time in this file.
    no warnings qw(redefine once);
    local *HTTP::Tiny::post = sub {
        my (undef, $url, undef) = @_;
        push @seen, $url;
        # Returning a successful empty response keeps select_blocks happy.
        return { success => 1, status => 200, content => '', headers => {} };
    };
    ClickHouse::Encoder->select_blocks(
        'select 1',
        on_block    => sub { },
        host        => 'h.example',
        settings    => { max_execution_time => 7 },
        dedup_token => 'should-be-stripped',
    );
    is(scalar @seen, 1, 'select_blocks POSTed exactly once');
    like($seen[0], qr/max_execution_time=7/,
         'select_blocks: settings forwarded to URL');
    unlike($seen[0], qr/insert_deduplication_token/,
           'select_blocks: dedup_token stripped (INSERT-only)');
    like($seen[0], qr{^http://h\.example:},
         'select_blocks: host honored');
    like($seen[0], qr/default_format=Native/,
         'select_blocks: default_format=Native appended');
}

# Live integration: only when a CH server is reachable on the standard
# HTTP port. Drops a tiny table, inserts a few rows, then SELECTs them
# back via select_blocks and confirms the block stream is well-formed
# and that the keep filter projects correctly.
SKIP: {
    require HTTP::Tiny;
    my $http = HTTP::Tiny->new(timeout => 1);
    my $ping = $http->get('http://127.0.0.1:18123/ping');
    skip 'ClickHouse HTTP not reachable on :18123', 4
        unless $ping->{success} && $ping->{content} =~ /Ok/;

    $http->post('http://127.0.0.1:18123/?query='
        . 'drop+table+if+exists+ch_sb_t',
        { content => '', headers => { 'Content-Length' => 0 } });
    $http->post('http://127.0.0.1:18123/?query='
        . 'create+table+ch_sb_t+(id+Int32%2Cevent+String%2Cts+DateTime)'
        . '+engine%3DMemory',
        { content => '', headers => { 'Content-Length' => 0 } });

    my $enc = ClickHouse::Encoder->new(columns =>
        [['id','Int32'],['event','String'],['ts','DateTime']]);
    ClickHouse::Encoder->insert_http(
        host => '127.0.0.1', port => 18123,
        table => 'ch_sb_t', columns => $enc->columns,
        rows  => [[1,'a',1700000000],
                  [2,'b',1700000001],
                  [3,'c',1700000002]]);

    # All columns
    my @all_ids;
    ClickHouse::Encoder->select_blocks(
        'select id, event, ts from ch_sb_t order by id',
        host => '127.0.0.1', port => 18123,
        on_block => sub {
            my $b = shift;
            for my $col (@{ $b->{columns} }) {
                push @all_ids, @{ $col->{values} } if $col->{name} eq 'id';
            }
        });
    is_deeply(\@all_ids, [1, 2, 3], 'select_blocks: returns all rows');

    # Projection
    my (@kept_ids, $payload_seen);
    ClickHouse::Encoder->select_blocks(
        'select id, event, ts from ch_sb_t order by id',
        host => '127.0.0.1', port => 18123,
        keep => { id => 1, ts => 1 },
        on_block => sub {
            my $b = shift;
            for my $col (@{ $b->{columns} }) {
                $payload_seen = 1 if $col->{name} eq 'event' && !$col->{skipped};
                push @kept_ids, @{ $col->{values} } if $col->{name} eq 'id';
            }
        });
    is_deeply(\@kept_ids, [1, 2, 3], 'projection: id intact');
    ok(!$payload_seen, 'projection: event column not materialized');

    $http->post('http://127.0.0.1:18123/?query=drop+table+ch_sb_t',
        { content => '', headers => { 'Content-Length' => 0 } });
    ok(1, 'live select_blocks scenario completed without exception');
}

done_testing();
