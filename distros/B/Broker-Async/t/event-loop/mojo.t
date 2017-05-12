use strict;
use warnings;
use Broker::Async;
use Test::Broker::Async::Utils;
use Test::More;

BEGIN {
    eval { require Future::Mojo; require Mojo::IOLoop; 1 }
        or plan skip_all => 'Future::Mojo or Mojo::IOLoop support not available';
}

subtest 'multi-worker concurrency' => sub {
    my $loop   = Mojo::IOLoop->singleton;
    my $code   = sub { Future::Mojo->new_timer($loop, 0) };
    my $broker = Broker::Async->new(
        workers => [ ($code)x 2 ],
    );

    test_event_loop($broker, [1 .. 5], 'mojo');
};

subtest 'per worker concurrency' => sub {
    my $loop   = Mojo::IOLoop->singleton;
    my $code   = sub { Future::Mojo->new_timer($loop, 0) };
    my $broker = Broker::Async->new(
        workers => [{code => $code, concurrency => 2}],
    );

    test_event_loop($broker, [1 .. 5], 'mojo');
};

done_testing;
