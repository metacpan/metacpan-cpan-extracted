use strict;
use warnings;

use Async::Event::Interval;
use Test::More;

my $mod = 'Async::Event::Interval';

# Throws
{
    my $ok = eval {
        $mod->new('a', sub {});
        1;
    };
    is $ok, undef, "croaks if interval isn't an int or float";
    like
        $@,
        qr/must be an integer or float/,
        "...and error is sane";
}
# OK
{
    my $ok_int = eval {
        $mod->new(1, sub {});
        1;
    };
    is $ok_int, 1, "interval() succeeds with int ok";

    $mod->new(0.15, sub {});
    my $ok_float = eval {
        $mod->new(0.15, sub {});
        1;
    };
    is $ok_float, 1, "interval() succeeds with float ok";
}

# Test timed interval

my $e = $mod->new(0.2, \&perform);

my $x = $e->shared_scalar;
$$x = 0;

is $$x, 0, "baseline var ok";

$e->start;

sleep 1;

is $$x >= 20, 1, "event is async and correct";

$e->stop;

# Change interval
my $e1 = $mod->new(0.2, \&change_interval);

my $y = $e1->shared_scalar;
$$y = 0;

$e1->start;
select(undef, undef, undef, 0.3);
is $$y > 0, 1, "With interval of 0.2, execution runs at the right time";

$e1->stop;
$e1->interval(1);
$e1->start;

$$y = 0;
select(undef, undef, undef, 0.8);
is $$y, 0, "Changing interval to 1 second, execution waits properly";

$e1->stop;

sub perform {
    $$x += 10;
}
sub change_interval {
    $$y++;
}
done_testing();
