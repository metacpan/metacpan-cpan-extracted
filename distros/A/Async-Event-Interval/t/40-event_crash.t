use strict;
use warnings;

use Async::Event::Interval;
use Test::More;

my $event = Async::Event::Interval->new(
    2,
    sub {
        kill 9, $$;
    },
);

$event->start;
is $event->status > 0, 1, "status ok at start";

sleep 1;

is $event->status, -1, "upon crash, status return ok";

if ($event->status == -1){
    $event->restart;
    is $event->status > 0, 1, "after restart, status ok again";
}

done_testing();

