use strict;
use warnings;

use Async::Event::Interval;
use Test::More;
use Time::HiRes qw(time);

my $mod = 'Async::Event::Interval';

# Test timed interval

my $e = $mod->new(1.7, \&perform);

my $t = $e->shared_scalar;
$$t = time;
$e->start;
sleep 2;
$e->stop;

sub perform {
    my $time = time;
    return if $time - $$t < 1;
    is $time - $$t > 1.6 && $time - $$t < 1.85, 1, "Event is 1.7 seconds ok";
    done_testing();
}

