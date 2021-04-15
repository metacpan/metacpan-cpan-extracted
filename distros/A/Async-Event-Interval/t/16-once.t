use strict;
use warnings;

use Async::Event::Interval;
use Time::HiRes qw(usleep);
use Test::More;

my $mod = 'Async::Event::Interval';

my $e = $mod->new(0, sub {select(undef, undef, undef, 0.5)});

is $e->waiting, 1, "Before start, the event is waiting";

$e->start;

sleep 1;

is $e->status, -1, "Zero as interval runs event only once";
is $e->waiting, 1, "Zero as interval sets waiting to true";

$e->start;
is $e->waiting, 0, "An event doesn't set waiting until after it's done";

sleep 1;

is $e->waiting, 1, "Event sets waiting after it completes";

done_testing();
