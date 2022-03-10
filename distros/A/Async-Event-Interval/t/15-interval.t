use strict;
use warnings;

use Async::Event::Interval;
use Data::Dumper;
use Test::More;

if (! $ENV{CI_TESTING}) {
    plan skip_all => "Not on a valid CI testing platform..."
}

my $mod = 'Async::Event::Interval';
my $events_hold = $mod->new(0, sub {});

# Throws
#{
#    my $ok = eval {
#        my $e = $mod->new('a', sub {});
#        1;
#    };
#    is $ok, undef, "croaks if interval isn't an int or float";
#    like
#        $@,
#        qr/must be an integer or float/,
#        "...and error is sane";
#}
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

sleep 1;

is $e->runs >= 4, 1, "event is async and correct";

$e->stop;

# Change interval
my $e1 = $mod->new(0.2, sub {});

$e1->start;

select(undef, undef, undef, 0.3);
is $e1->runs, 1, "With interval of 0.2, execution runs at the right time";

select(undef, undef, undef, 0.7);

my $runs_02 = $e1->runs;
is $runs_02 > 3, 1, "With interval of 0.2, execution happens at the proper rate";

$e1->interval(2);

select(undef, undef, undef, 1.8);
my $runs_2 = $e1->runs;
my $runs_diff = $runs_2 - $runs_02;

is
    $runs_diff,
    1,
    "Changing interval to 2, execution waits properly";

$e1->stop;

done_testing();
