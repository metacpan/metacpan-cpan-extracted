use strict;
use warnings;
use Broker::Async;
use Broker::Async::Worker;
use List::Util qw( shuffle );
use Test::Broker::Async::Utils;
use Test::More;

subtest 'multi-worker concurrency' => sub {
    my $trace  = new_tracer();
    my $broker = Broker::Async->new(
        workers => [ ($trace->worker)x 2 ],
    );

    $broker->do($_) for 1 .. 3;
    is_deeply $trace->live,
              [1, 2],
              'broker doesnt concurrently run more tasks than number of workers';

    $trace->futures->{1}->done;
    is_deeply $trace->live,
              [2, 3],
              'broker runs another task after first resolves';
};

subtest 'order of execution' => sub {
    my $trace = new_tracer();
    my %tasks = map { $_ => Future->new } 1 .. 100;

    my $broker = Broker::Async->new(
        workers => [ ($trace->worker)x 10 ],
    );

    $broker->do($_) for 1 .. 100;
    while (my @live = @{ $trace->live }) {
        $trace->futures->{$_}->done for shuffle @live;
    }

    is_deeply $trace->started, [ 1 .. 100 ], 'broker starts tasks in the order they are seen';
};

subtest 'per worker concurrency' => sub {
    my $trace = new_tracer();

    my $broker = Broker::Async->new(
        workers => [{code => $trace->worker, concurrency => 2}],
    );

    $broker->do($_) for 1 .. 3;
    is_deeply $trace->live, [1, 2], 'broker respects worker concurrency limit';

    $trace->futures->{1}->done;
    is_deeply $trace->live, [2, 3], 'broker runs another task after first resolves';
};

subtest 'worker constructor' => sub {
    subtest 'from code' => sub {
        my $code   = sub { Future->done };
        my $broker = Broker::Async->new(
            workers => [ $code ],
        );

        my $worker = $broker->workers->[0];
        is $worker->code, $code, 'worker uses code argument';
        is $worker->concurrency, 1, 'worker has default concurrency of 1';
    };

    subtest 'from hashref' => sub {
        my $code   = sub { Future->done };
        my $max    = 5;
        my $broker = Broker::Async->new(
            workers => [{code => $code, concurrency => $max}],
        );

        my $worker = $broker->workers->[0];
        is $worker->code, $code, 'worker uses code argument';
        is $worker->concurrency, $max, 'worker uses concurrency argument';
    };

    subtest 'from worker object' => sub {
        my $worker = Broker::Async::Worker->new(code => sub { Future->new });
        my $broker = Broker::Async->new(
            workers => [ $worker ],
        );
        is $broker->workers->[0], $worker, 'broker uses worker as is';
    };
};

done_testing;
