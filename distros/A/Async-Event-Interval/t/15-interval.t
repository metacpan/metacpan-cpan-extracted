use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

{
    my $events_hold = $mod->new(0, sub {});

    # OK
    {
        my $ok_int = eval {
            my $e = $mod->new(1, sub {});
            1;
        };
        is $ok_int, 1, "interval() succeeds with int ok";

        my $ok_float = eval {
            my $e = $mod->new(0.15, sub {});
            1;
        };
        is $ok_float, 1, "interval() succeeds with float ok";
    }

    # Test timed interval

    my $e = $mod->new(0.2, sub {});

    is $e->runs, 0, "Baseline ok";

    $e->start;

    sleep 2;

    is $e->runs >= 4, 1, "event is async and correct";

    $e->stop;

    # Change interval
    my $e1 = $mod->new(0.2, sub {});

    $e1->start;

    select(undef, undef, undef, 1.0);
    is $e1->runs >= 1, 1, "With interval of 0.2, execution runs at the right time";

    select(undef, undef, undef, 1.7);

    my $runs_02 = $e1->runs;
    is $runs_02 > 3, 1, "With interval of 0.2, execution happens at the proper rate";

    $e1->interval(2);

    select(undef, undef, undef, 1.8);
    my $runs_2 = $e1->runs;
    my $runs_diff = $runs_2 - $runs_02;

    is
        $runs_diff >= 1,
        1,
        "Changing interval to 2, execution waits properly";

    $e1->stop;
}
