use strict;
use warnings;
use Coro;
use AnyEvent;
use Coro::Countdown;
use Test2::Bundle::Extended;

ok my $counter = new Coro::Countdown;
is $counter->count, 0, 'initial count';

my $cv_init = AE::cv;
async { $counter->join; $cv_init->send('sent') };
is $cv_init->recv, 'sent', 'signaled';

is $counter->up, 1, 'up';
is $counter->up, 2, 'up';
is $counter->up, 3, 'up';
is $counter->count, 3, 'count';

my $cv_sig = AE::cv;
async { $counter->join; $cv_sig->send('sent') };

async {
  is $counter->down, 2, 'down';
  is $counter->down, 1, 'down';
  is $counter->down, 0, 'down';
};

is $cv_sig->recv, 'sent', 'signaled';
is $counter->count, 0, 'final count';

done_testing;
