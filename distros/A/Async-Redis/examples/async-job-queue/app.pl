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

use constant QUEUE_KEY     => 'async-job-queue:jobs';
use constant PROCESSED_KEY => 'async-job-queue:processed';
use constant IN_FLIGHT_KEY => 'async-job-queue:in-flight';
use constant STOP_SENTINEL => '__async_job_queue_stop__';

my $opts = parse_options();

eval {
    main($opts)->get;
    1;
} or do {
    my $error = $@ || 'unknown error';
    chomp $error;
    warn "async-job-queue: $error\n";
    exit 1;
};

exit 0;

sub parse_options {
    my %opts = (
        jobs      => 10,
        workers   => 2,
        delay     => 1.5,
        heartbeat => 0.25,
    );

    my $help;
    GetOptions(
        'jobs=i'    => \$opts{jobs},
        'workers=i' => \$opts{workers},
        'delay=f'   => \$opts{delay},
        'help|h'    => \$help,
    ) or die usage();

    if ($help) {
        print usage();
        exit 0;
    }

    die "--jobs must be a positive integer\n"   unless $opts{jobs} =~ /\A[1-9][0-9]*\z/;
    die "--workers must be a positive integer\n" unless $opts{workers} =~ /\A[1-9][0-9]*\z/;
    die "--delay must be a positive number\n"   unless $opts{delay} > 0;

    return \%opts;
}

sub usage {
    return <<'USAGE';
Usage: examples/async-job-queue/app.pl [options]

Options:
  --jobs N       number of jobs to enqueue, default 10
  --workers N    number of workers, default 2
  --delay SEC    simulated seconds per job, default 1.5
  --help         show this help

Environment:
  REDIS_HOST     Redis hostname, default localhost
  REDIS_PORT     Redis port, default 6379
USAGE
}

async sub main {
    my ($opts) = @_;
    my $start = time();
    my $controller = await connect_redis('controller');

    await cleanup_demo_keys($controller);
    await enqueue_jobs($controller, $opts->{jobs}, $start);

    my @worker_futures = map {
        worker($_, $opts, $start);
    } 1 .. $opts->{workers};

    my $heartbeat_f = heartbeat($opts, $start);

    await wait_until_processed($controller, $opts->{jobs});
    await push_stop_sentinels($controller, $opts->{workers});
    await Future->needs_all(@worker_futures, $heartbeat_f);

    my $processed = await processed_count($controller);
    await cleanup_after_run($controller);

    my $elapsed = time() - $start;
    my $sequential = $opts->{jobs} * $opts->{delay};
    log_line(
        $start,
        sprintf(
            'done processed=%d workers=%d elapsed=%.2fs sequential_about=%.2fs',
            $processed,
            $opts->{workers},
            $elapsed,
            $sequential,
        ),
    );

    $controller->disconnect;
    return;
}

sub redis_args {
    return (
        host            => $ENV{REDIS_HOST} // 'localhost',
        port            => $ENV{REDIS_PORT} // 6379,
        connect_timeout => 2,
    );
}

async sub connect_redis {
    my ($role) = @_;
    my $redis = Async::Redis->new(redis_args());

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

async sub cleanup_demo_keys {
    my ($redis) = @_;
    await $redis->del(QUEUE_KEY, PROCESSED_KEY, IN_FLIGHT_KEY);
    return;
}

async sub cleanup_after_run {
    my ($redis) = @_;
    await $redis->lrem(QUEUE_KEY, 0, STOP_SENTINEL);
    await $redis->del(IN_FLIGHT_KEY);
    return;
}

async sub enqueue_jobs {
    my ($redis, $jobs, $start) = @_;
    my @jobs = map { "job-$_" } 1 .. $jobs;
    await $redis->rpush(QUEUE_KEY, @jobs);

    my $queued = await $redis->llen(QUEUE_KEY);
    log_line($start, "queued $queued jobs");
    return;
}

async sub worker {
    my ($id, $opts, $start) = @_;
    my $name = "worker-$id";
    my $redis = await connect_redis($name);

    my $ok = eval {
        while (1) {
            my $entry = await $redis->blpop(QUEUE_KEY, 0);
            next unless $entry;

            my ($queue, $job) = @$entry;
            if ($job eq STOP_SENTINEL) {
                log_line($start, "$name stopped");
                last;
            }

            await $redis->sadd(IN_FLIGHT_KEY, $job);
            log_line($start, "$name started $job");

            my $processed;
            my $job_ok = eval {
                await Future::IO->sleep($opts->{delay});
                await $redis->srem(IN_FLIGHT_KEY, $job);
                $processed = await $redis->incr(PROCESSED_KEY);
                1;
            };
            my $job_error = $@;

            if (!$job_ok) {
                eval { await $redis->srem(IN_FLIGHT_KEY, $job); 1 };
                die $job_error;
            }

            log_line($start, "$name finished $job processed=$processed");
        }

        1;
    };
    my $error = $@;

    $redis->disconnect;
    die $error unless $ok;
    return;
}

async sub heartbeat {
    my ($opts, $start) = @_;
    my $redis = await connect_redis('stats');

    my $ok = eval {
        while (1) {
            await Future::IO->sleep($opts->{heartbeat});

            my ($queue_depth, $in_flight, $processed) = await Future->needs_all(
                $redis->llen(QUEUE_KEY),
                $redis->scard(IN_FLIGHT_KEY),
                $redis->get(PROCESSED_KEY),
            );
            $processed //= 0;

            log_line(
                $start,
                "heartbeat queue=$queue_depth in_flight=$in_flight processed=$processed",
            );

            last if $processed >= $opts->{jobs} && $queue_depth == 0 && $in_flight == 0;
            await Future::IO->sleep($opts->{heartbeat});
        }

        1;
    };
    my $error = $@;

    $redis->disconnect;
    die $error unless $ok;
    return;
}

async sub wait_until_processed {
    my ($redis, $target) = @_;

    while (1) {
        my $processed = await processed_count($redis);
        return if $processed >= $target;
        await Future::IO->sleep(0.05);
    }
}

async sub push_stop_sentinels {
    my ($redis, $workers) = @_;
    await $redis->rpush(QUEUE_KEY, map { STOP_SENTINEL } 1 .. $workers);
    return;
}

async sub processed_count {
    my ($redis) = @_;
    return (await $redis->get(PROCESSED_KEY)) // 0;
}

sub log_line {
    my ($start, $message) = @_;
    printf "[%5.2fs] %s\n", time() - $start, $message;
    return;
}
