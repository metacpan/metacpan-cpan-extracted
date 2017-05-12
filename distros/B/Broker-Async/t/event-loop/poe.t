use strict;
use warnings;
use Broker::Async;
use Test::Broker::Async::Utils;
use Test::More;

BEGIN {
    eval { require POE::Future; require POE; 1 }
        or plan skip_all => 'POE::Future or POE not available';
}
POE::Kernel->run;

subtest 'multi-worker concurrency' => sub {
    my $code   = sub { POE::Future->new_delay(after => 0) };
    my $broker = Broker::Async->new(
        workers => [ ($code)x 2 ],
    );

    test_event_loop($broker, [1 .. 5], 'poe');
};

subtest 'per worker concurrency' => sub {
    my $code   = sub { POE::Future->new_delay(after => 0) };
    my $broker = Broker::Async->new(
        workers => [{code => $code, concurrency => 2}],
    );

    test_event_loop($broker, [1 .. 5], 'poe');
};

done_testing;
