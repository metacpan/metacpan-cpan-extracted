#!/usr/bin/env perl
# Drain a Redis stream (or list) into a ClickHouse table. Useful for
# the typical metrics / events pipeline where producers RPUSH /
# XADD into Redis as a fast inbox and a downstream worker batches
# the data into a CH table.
#
# Two source modes via SOURCE_KIND env var:
#   stream  - XREADGROUP from a Redis stream (consumer-group, with ack)
#   list    - LPOP/BRPOP from a Redis list (lighter-weight, no ack)
#
# Usage:
#     CH_PORT=8123 \
#     REDIS_URL=redis://localhost:6379 \
#     SOURCE_KEY=events \
#     SOURCE_KIND=list \
#     perl eg/redis_to_clickhouse.pl events
#
# Each Redis entry is a JSON object whose fields map to the table's
# columns (column names discovered via for_table).

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use HTTP::Tiny;
use JSON::PP;
use Redis;

my $table     = shift @ARGV or die "Usage: $0 <table>\n";
my $port      = $ENV{CH_PORT}     // 8123;
my $redis_url = $ENV{REDIS_URL}   // 'redis://localhost:6379';
my $key       = $ENV{SOURCE_KEY}  // $table;
my $kind      = $ENV{SOURCE_KIND} // 'list';
my $batch     = $ENV{BATCH}       // 1000;
my $idle_ms   = $ENV{IDLE_MS}     // 5000;

my $enc   = ClickHouse::Encoder->for_table($table, via=>'http', port=>$port);
my @cols  = @{ $enc->columns };
my @names = map { $_->[0] } @cols;
my %nullable = map { $_->[0] => ($_->[1] =~ /\ANullable\(/ ? 1 : 0) } @cols;

(my $host_port = $redis_url) =~ s{^redis://}{};
my $redis = Redis->new(server => $host_port);

my $http = HTTP::Tiny->new(timeout => 30);
my $url  = "http://localhost:$port/?query="
         . _esc("insert into $table format native");
my $writer = sub {
    my $resp = $http->post($url, {
        content => $_[0],
        headers => { 'Content-Type' => 'application/octet-stream' },
    });
    die "insert failed (status $resp->{status}): $resp->{content}"
        unless $resp->{success};
};

my $st   = $enc->streamer($writer, batch_size => $batch);
my $json = JSON::PP->new->utf8;

# --- list mode: BRPOP loop, idle-flush after IDLE_MS of no traffic ---
if ($kind eq 'list') {
    my $last_seen = time();
    while (1) {
        my $popped = $redis->brpop($key, 1);
        if ($popped) {
            push_record($popped->[1]);
            $last_seen = time();
        } elsif ($st->buffered_count > 0
                 && (time() - $last_seen) * 1000 > $idle_ms) {
            $st->finish;
            $last_seen = time();
        }
    }
}
# --- stream mode: XREADGROUP, ack on success ---
elsif ($kind eq 'stream') {
    my $group    = $ENV{GROUP}    // 'ch-loader';
    my $consumer = $ENV{CONSUMER} // "ch-loader-$$";
    eval { $redis->xgroup('CREATE', $key, $group, '$', 'MKSTREAM') };
    while (1) {
        my $batch_resp = $redis->xreadgroup(
            'GROUP', $group, $consumer,
            'COUNT', $batch, 'BLOCK', 5000,
            'STREAMS', $key, '>',
        ) or next;
        for my $stream (@$batch_resp) {
            for my $entry (@{ $stream->[1] }) {
                my ($id, $kv) = @$entry;
                # Convert flat field/value array to hash.
                my %h = @$kv;
                push_record(exists $h{json} ? $h{json} : $json->encode(\%h));
                $redis->xack($key, $group, $id);
            }
        }
    }
}
else {
    die "Unknown SOURCE_KIND='$kind' (expected 'list' or 'stream')";
}

sub push_record {
    my $payload = shift;
    my $rec = eval { $json->decode($payload) };
    return if $@;
    my @row;
    for my $name (@names) {
        if (exists $rec->{$name}) { push @row, $rec->{$name} }
        elsif ($nullable{$name})  { push @row, undef }
        else { warn "skip record missing required '$name'\n"; return }
    }
    $st->push_row(\@row);
}

sub _esc {
    (my $s = $_[0]) =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
}
