use strict;
use warnings;
use Broker::Async;
use Test::Broker::Async::Utils;
use Test::More;

BEGIN {
    eval { require AnyEvent::Future; 1 }
        or plan skip_all => 'AnyEvent::Future not available';
}


subtest 'multi-worker concurrency' => sub {
    my $code   = sub { AnyEvent::Future->new_delay(after => 0) };
    my $broker = Broker::Async->new(
        workers => [ ($code)x 2 ],
    );

    test_event_loop($broker, [1 .. 5], 'anyevent');
};

subtest 'per worker concurrency' => sub {
    my $code   = sub { AnyEvent::Future->new_delay(after => 0) };
    my $broker = Broker::Async->new(
        workers => [{code => $code, concurrency => 2}],
    );

    test_event_loop($broker, [1 .. 5], 'anyevent');
};

done_testing;
