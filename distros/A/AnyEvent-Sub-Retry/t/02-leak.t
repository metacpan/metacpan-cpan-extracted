use strict;
use warnings;
use Test::More;

use AnyEvent::Sub::Retry;
use Test::LeakTrace;

my $call_count = 0;
my $t;
my $now = AnyEvent->time;
my $code_ref = sub {
    $call_count ++;
    my $cv = AE::cv;
    my $should_return_success = $call_count == 1 ? 0 : 1;
    $t = AnyEvent->timer(
        cb => sub {
            if ($should_return_success) {
                $cv->send('foo', 'var');
            } else {
                $cv->croak('error!');
            }
        }
    );
    return $cv;
};

no_leaks_ok {
    my $cv = retry 2, 0.1, $code_ref;
    $cv->recv;
};
done_testing;

1;
