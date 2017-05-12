use strict;
use warnings;

use Test::More 'no_plan';

use_ok 'Benchmark::Stopwatch';

my $sw = Benchmark::Stopwatch->new;
isa_ok $sw, 'Benchmark::Stopwatch';

# Overide the '_time' function for testing.
my $COUNTER = 0;
$sw->{_time} = sub {
    $COUNTER++;
};

is $sw->time, 0, "got 0";
is $sw->time, 1, "got 1";
$COUNTER = 0;

$sw->start;
$sw->lap('one');
$sw->lap('two');
$sw->lap('one');
$sw->stop;

is_deeply $sw,
  {
    start  => 0,
    events => [
        { name => 'one', time => 1 },
        { name => 'two', time => 2 },
        { name => 'one', time => 3 },
    ],
    stop  => 4,
    _time => $sw->{_time},
  },
  "laps recorded correctly";
