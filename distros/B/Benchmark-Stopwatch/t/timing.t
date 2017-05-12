use strict;
use warnings;

use Test::More 'no_plan';

use Time::HiRes;
use_ok 'Benchmark::Stopwatch';

# Run the tests twice, once not stopping, once stopping.
foreach my $should_stop ( 0, 1 ) {
    my $sw = Benchmark::Stopwatch->new;
    isa_ok $sw, 'Benchmark::Stopwatch';

    my $start_pre = Time::HiRes::time;
    $sw->start;
    my $start_post = Time::HiRes::time;
    my $total      = 0;

    # Twiddle thumbs....
    Time::HiRes::time for 1 .. 100;

    my $min = Time::HiRes::time - $start_post;

    # If we should stop the watch then do so, otherwise just note down the time.
    if   ($should_stop) { $sw->stop; }
    else                { $total = $sw->total_time; }

    my $max = Time::HiRes::time - $start_pre;

    $total = $sw->total_time if $should_stop;

    ok $total > $min, "\$sw->total is more than min";
    ok $total < $max, "\$sw->total is less than max";
}

# use Data::Dumper;
#
# warn Dumper {
#     total => $sw->total,
#     min   => $min,
#     max   => $max,
# };
