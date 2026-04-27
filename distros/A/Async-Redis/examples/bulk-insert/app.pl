#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Async::Redis;
use Future;
use Future::AsyncAwait;
use Future::IO;
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time);

$| = 1;

my $opts = parse_options();

eval {
    main($opts)->get;
    1;
} or do {
    my $error = $@ || 'unknown error';
    chomp $error;
    warn "bulk-insert: $error\n";
    exit 1;
};

exit 0;

sub parse_options {
    my %opts = (
        count         => 50_000,
        batch         => 500,
        ttl           => 120,
        payload_bytes => 128,
        heartbeat     => 0.25,
    );

    my $help;
    GetOptions(
        'count=i'         => \$opts{count},
        'batch=i'         => \$opts{batch},
        'ttl=i'           => \$opts{ttl},
        'payload-bytes=i' => \$opts{payload_bytes},
        'heartbeat=f'     => \$opts{heartbeat},
        'help|h'          => \$help,
    ) or die usage();

    if ($help) {
        print usage();
        exit 0;
    }

    die "--count must be a positive integer\n"         unless $opts{count} =~ /\A[1-9][0-9]*\z/;
    die "--batch must be a positive integer\n"         unless $opts{batch} =~ /\A[1-9][0-9]*\z/;
    die "--ttl must be a positive integer\n"           unless $opts{ttl} =~ /\A[1-9][0-9]*\z/;
    die "--payload-bytes must be a positive integer\n" unless $opts{payload_bytes} =~ /\A[1-9][0-9]*\z/;
    die "--heartbeat must be a positive number\n"      unless $opts{heartbeat} > 0;

    return \%opts;
}

sub usage {
    return <<'USAGE';
Usage: examples/bulk-insert/app.pl [options]

Options:
  --count N           keys to insert, default 50000
  --batch N           concurrent SETs per batch, default 500
  --ttl SEC           expiry for inserted keys, default 120
  --payload-bytes N   value size per key, default 128
  --heartbeat SEC     heartbeat interval, default 0.25
  --help              show this help

Environment:
  REDIS_HOST          Redis hostname, default localhost
  REDIS_PORT          Redis port, default 6379
USAGE
}

async sub main {
    my ($opts) = @_;
    my $start = time();
    my $prefix = sprintf 'bulk-insert:%d:%d:', $$, int($start * 1000);

    my $writer = await connect_redis('writer', auto_pipeline => 1);
    my $stats  = await connect_redis('stats');

    my $state = {
        issued    => 0,
        confirmed => 0,
        batches   => 0,
        done      => 0,
    };

    log_line(
        $start,
        sprintf(
            'starting count=%d batch=%d payload=%dB ttl=%ds prefix=%s',
            $opts->{count},
            $opts->{batch},
            $opts->{payload_bytes},
            $opts->{ttl},
            $prefix,
        ),
    );

    my $heartbeat_f = heartbeat($stats, $state, $opts, $start);

    my $ok = eval {
        await insert_keys($writer, $state, $opts, $prefix);
        1;
    };
    my $error = $@;

    $state->{done} = 1;
    eval { await $heartbeat_f; 1 };

    $writer->disconnect;
    $stats->disconnect;

    die $error unless $ok;

    my $elapsed = time() - $start;
    my $rate = $elapsed > 0 ? $state->{confirmed} / $elapsed : 0;
    log_line(
        $start,
        sprintf(
            'done inserted=%d batches=%d elapsed=%.2fs rate=%.0f/s keys_expire_in=%ds',
            $state->{confirmed},
            $state->{batches},
            $elapsed,
            $rate,
            $opts->{ttl},
        ),
    );

    return;
}

sub redis_args {
    my (%extra) = @_;
    return (
        host            => $ENV{REDIS_HOST} // 'localhost',
        port            => $ENV{REDIS_PORT} // 6379,
        connect_timeout => 2,
        %extra,
    );
}

async sub connect_redis {
    my ($role, %extra) = @_;
    my $redis = Async::Redis->new(redis_args(%extra));

    eval {
        await $redis->connect;
        1;
    } or do {
        my $error = $@ || 'unknown error';
        chomp $error;
        die "could not connect $role Redis client: $error\n";
    };

    return $redis;
}

async sub insert_keys {
    my ($redis, $state, $opts, $prefix) = @_;
    my $payload = 'x' x $opts->{payload_bytes};

    for (my $first = 1; $first <= $opts->{count}; $first += $opts->{batch}) {
        my $last = $first + $opts->{batch} - 1;
        $last = $opts->{count} if $last > $opts->{count};

        my @futures;
        for my $i ($first .. $last) {
            push @futures, $redis->set("$prefix$i", $payload, ex => $opts->{ttl});
        }

        $state->{issued} += scalar @futures;
        await Future->needs_all(@futures);
        $state->{confirmed} += scalar @futures;
        $state->{batches}++;

        # Give timer-based tasks a scheduling point between large batches.
        await Future::IO->sleep(0);
    }

    return;
}

async sub heartbeat {
    my ($redis, $state, $opts, $start) = @_;

    while (!$state->{done}) {
        await Future::IO->sleep($opts->{heartbeat});

        my $ping_start = time();
        await $redis->ping;
        my $ping_ms = (time() - $ping_start) * 1000;

        my $elapsed = time() - $start;
        my $rate = $elapsed > 0 ? $state->{confirmed} / $elapsed : 0;
        log_line(
            $start,
            sprintf(
                'heartbeat issued=%d confirmed=%d batches=%d ping_ms=%.1f rate=%.0f/s',
                $state->{issued},
                $state->{confirmed},
                $state->{batches},
                $ping_ms,
                $rate,
            ),
        );
    }

    return;
}

sub log_line {
    my ($start, $message) = @_;
    printf "[%5.2fs] %s\n", time() - $start, $message;
    return;
}
