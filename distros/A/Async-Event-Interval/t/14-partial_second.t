use strict;
use warnings;

use IPC::Shareable;
use Test::More;
use Time::HiRes qw(time);

my ($segs_before, $sems_before);
BEGIN {
    IPC::Shareable->testing_set('Async::Event::Interval');
    $segs_before = IPC::Shareable::seg_count();
    $sems_before = IPC::Shareable::sem_count();
}

use Async::Event::Interval;

warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};
warn "Sems Before: $sems_before\n" if $ENV{PRINT_SEGS};

my $mod = 'Async::Event::Interval';

# Test timed interval

my $e = $mod->new(1.6, \&perform);

my $t = $e->shared_scalar;
$$t = time;
$e->start;
sleep 2;
$e->stop;

sub perform {
    my $time = time;
    is $time - $$t > 1.6 && $time - $$t < 1.85, 1, "Event is 1.6 seconds ok";
    done_testing();
}