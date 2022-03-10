use strict;
use warnings;

use Async::Event::Interval;
use Time::HiRes qw(usleep);
use Test::More;

if (! $ENV{CI_TESTING}) {
    plan skip_all => "Not on a valid CI testing platform..."
}

my $mod = 'Async::Event::Interval';

my $e = $mod->new(0, sub {select(undef, undef, undef, 0.5)});

is $e->waiting, 1, "Before start, the event is waiting";

$e->start;

sleep 1;

is $e->status, 0, "Zero as interval sets status to complete (0)";
is $e->error, 1, "Zero as interval sets error to true";
is $e->_pid, -99, "Zero as interval sets _pid to -99";
is $e->waiting, 1, "Zero as interval sets waiting to true";

$e->start;
is $e->waiting, 0, "An event doesn't set waiting until after it's done";

sleep 1;

is $e->waiting, 1, "Event sets waiting after it completes";

done_testing();
