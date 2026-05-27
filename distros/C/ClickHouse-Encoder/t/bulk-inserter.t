#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Constructor validation (no network)
{
    my $err = eval {
        ClickHouse::Encoder->bulk_inserter(
            table => 'foo; drop table bar',
            columns => [['x','Int32']]); 1
    } ? "" : $@;
    like($err, qr/Invalid table name/, 'rejects bad table name');
}

{
    my $err = eval {
        ClickHouse::Encoder->bulk_inserter(table => 't'); 1
    } ? "" : $@;
    like($err, qr/columns or encoder/, 'requires columns or encoder');
}

{
    my $err = eval {
        ClickHouse::Encoder->bulk_inserter(
            columns => [['x','Int32']]); 1
    } ? "" : $@;
    like($err, qr/needs table/, 'requires table');
}

# Inserter object shape (no flush yet, so no network)
{
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['x','Int32']], batch_size => 10);
    isa_ok($bi, 'ClickHouse::Encoder::BulkInserter');
    can_ok($bi, qw(push push_many flush finish
                   buffered_count sent_rows sent_batches));
    is($bi->buffered_count, 0, 'starts empty');
    is($bi->sent_batches,   0, 'no batches sent yet');
    $bi->push([1]);
    $bi->push([2]);
    $bi->push_many([[3],[4],[5]]);
    is($bi->buffered_count, 5, 'push and push_many accumulate');
    is($bi->sent_rows, 0, 'not yet flushed');
}

# push_many with N >> batch_size must respect batch_size (not send one
# oversized POST). We verify against an in-memory mock that records each
# flush. No live server needed.
{
    my @bodies;
    my $mock_http = bless {}, 'Test::MockHTTP';
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['x','Int32']], batch_size => 4);
    # Override the HTTP transport with the mock.
    *Test::MockHTTP::post = sub {
        my (undef, undef, $args) = @_;
        push @bodies, $args->{content};
        return { success => 1, status => 200, content => '' };
    };
    $bi->{http} = $mock_http;
    $bi->push_many([map [$_], 1..14]);  # 14 rows, batch_size=4
    $bi->finish;
    is(scalar @bodies, 4,
       "push_many(14 rows, batch_size=4) -> 4 batches (4+4+4+2)");
    is($bi->sent_rows, 14, 'push_many: total rows accounted for');
}

# Boundary: push_many of exactly batch_size rows fires exactly one
# POST when the loop body never executes (while $remaining >= bs is
# false on entry and the remainder happens to equal bs). Tests the
# loop entry/exit invariants.
{
    my @bodies;
    my $mock_http = bless {}, 'Test::MockHTTP';
    my $bi = ClickHouse::Encoder->bulk_inserter(
        table => 't', columns => [['x','Int32']], batch_size => 5);
    {
        no warnings 'redefine';
        *Test::MockHTTP::post = sub {
            my (undef, undef, $args) = @_;
            push @bodies, $args->{content};
            return { success => 1, status => 200, content => '' };
        };
    }
    $bi->{http} = $mock_http;
    $bi->push_many([map [$_], 1..5]);  # exactly == batch_size
    is(scalar @bodies, 1, 'push_many(N == batch_size) -> single POST');
    is($bi->buffered_count, 0, 'buffer drained after auto-flush');
    $bi->finish;
    is(scalar @bodies, 1, 'finish with empty buffer fires no extra POST');
    is($bi->sent_rows, 5, 'exact-batch: 5 rows accounted for');
}

# Live INSERT against 127.0.0.1:18123 if reachable
SKIP: {
    require HTTP::Tiny;
    my $http = HTTP::Tiny->new(timeout => 1);
    my $ping = $http->get("http://127.0.0.1:18123/ping");
    skip "ClickHouse HTTP not reachable on :18123", 6
        unless $ping->{success} && $ping->{content} =~ /Ok/;

    $http->post("http://127.0.0.1:18123/?query="
        . "drop+table+if+exists+ch_bi_t",
        { content => '', headers => { 'Content-Length' => 0 } });
    $http->post("http://127.0.0.1:18123/?query="
        . "create+table+ch_bi_t+(x+Int32%2Cs+String)+engine%3DMemory",
        { content => '', headers => { 'Content-Length' => 0 } });

    my $bi = ClickHouse::Encoder->bulk_inserter(
        host => '127.0.0.1', port => 18123, table => 'ch_bi_t',
        columns => [['x','Int32'],['s','String']],
        batch_size => 3);

    # 5 rows -> auto-flush at 3 + final flush of 2
    $bi->push([$_, "row$_"]) for 1..5;
    is($bi->sent_rows, 3, 'auto-flush at batch_size');
    my $info = $bi->finish;
    is($info->{rows},    5, 'finish reports total rows');
    is($info->{batches}, 2, 'finish reports total batches');

    my $count = $http->get(
        "http://127.0.0.1:18123/?query=select+count()+from+ch_bi_t");
    chomp(my $n = $count->{content});
    is($n, '5', 'all rows arrived');

    # Compressed inserter
    $http->post("http://127.0.0.1:18123/?query=truncate+table+ch_bi_t",
        { content => '', headers => { 'Content-Length' => 0 } });
    my $bi2;
    my $ok = eval {
        $bi2 = ClickHouse::Encoder->bulk_inserter(
            host => '127.0.0.1', port => 18123, table => 'ch_bi_t',
            columns => [['x','Int32'],['s','String']],
            batch_size => 100, compress => 'gzip');
        1
    };
    skip "IO::Compress::Gzip not available", 2 unless $ok;
    $bi2->push([$_, "g$_"]) for 1..10;
    $bi2->finish;
    $count = $http->get(
        "http://127.0.0.1:18123/?query=select+count()+from+ch_bi_t");
    chomp($n = $count->{content});
    is($n, '10', 'gzip-compressed insert worked');

    # 4xx error path (bad table after drop)
    $http->post("http://127.0.0.1:18123/?query=drop+table+ch_bi_t",
        { content => '', headers => { 'Content-Length' => 0 } });
    my $bi3 = ClickHouse::Encoder->bulk_inserter(
        host => '127.0.0.1', port => 18123, table => 'ch_bi_t',
        columns => [['x','Int32'],['s','String']],
        retries => 0);
    my $err = eval { $bi3->push([1,'x'])->flush; 1 } ? "" : $@;
    like($err, qr/HTTP \d/, '4xx error surfaces from flush');
}

done_testing();
