use strict;
use warnings;

use File::Temp;
use IPC::Shareable;
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();

# Reproduce the scratch.pl scenario: an event with a timeout shorter
# than its callback's sleep.  The host process is killed by SIGINT
# while the event is running.  Before the _end() fix, the %events
# parent and child segments leaked because _end() skipped cleanup
# when _event_count > 0 and DESTROY never ran (global destruction
# skipped on signal death).

my $flag_file = File::Temp::tmpnam();

my $pid = fork;
die "fork: $!" unless defined $pid;

if (! $pid) {
    IPC::Shareable->testing_set('Async::Event::Interval');
    require Async::Event::Interval;

    my $event = Async::Event::Interval->new(5, sub {
        open my $fh, '>', $flag_file;
        close $fh;
        sleep 4;
    });
    $event->immediate(1);
    $event->timeout(3);
    $event->start;

    sleep 60;
    exit;
}

for (1..50) {
    last if -e $flag_file;
    select(undef, undef, undef, 0.1);
}

ok -e $flag_file, "Event callback was invoked before SIGINT";

kill 'INT', $pid;
waitpid $pid, 0;
select(undef, undef, undef, 0.3);

unlink $flag_file if -e $flag_file;

my $segs_after = IPC::Shareable::seg_count();
my $sems_after = IPC::Shareable::sem_count();

is $segs_after, $segs_before,
    "No segments leaked after SIGINT kills event host process";

is $sems_after, $sems_before,
    "No semaphores leaked after SIGINT kills event host process";

done_testing();
