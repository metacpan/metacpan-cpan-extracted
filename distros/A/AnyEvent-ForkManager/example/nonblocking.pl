use strict;
use warnings;

use AnyEvent;
use AnyEvent::ForkManager;
use List::Util qw/shuffle/;

my $MAX_WORKERS = 10;
my $pm = AnyEvent::ForkManager->new(max_workers => $MAX_WORKERS);

$pm->on_start(sub{
    my($pm, $pid, $data) = @_;

    printf("started child proccess. {pid => %d, sleep_time => %d}\n", $pid, $data);
});

$pm->on_finish(sub{
    my($pm, $pid, $status, $data) = @_;

    printf("finished child proccess. {pid => %d, status => %d, sleep_time => %d}\n", $pid, $status >> 8, $data);
});

$pm->on_enqueue(sub{
    my($pm, $data) = @_;

    printf("enqueued start child proccess. {sleep_time => %d}\n", $data);
});

$pm->on_dequeue(sub{
    my($pm, $data) = @_;

    printf("dequeued start child proccess. {sleep_time => %d}\n", $data);
});

$pm->on_working_max(sub{
    my($pm, $data) = @_;

    printf("working child process count is max. yet start process {sleep_time => %d}\n", $data);
});

$pm->on_error(sub{
    my($pm, $data) = @_;

    printf("fork failed. on dispatch %d. object => %s.}\n", $data, $pm);
});

my @all_data = shuffle(1 .. $MAX_WORKERS * 2);
foreach my $data (@all_data) {
    $pm->start(
        cb => sub {
            my($pm, $data) = @_;
            sleep $data;
            printf("Slept %d sec.\n", $data);
            my $exit_code = $data;
            printf("  Exit code = %d\n", $exit_code);
            $pm->finish($exit_code);
        },
        args => [$data]
    );
}

my $cv = AnyEvent->condvar;
$pm->wait_all_children(
    cb => sub {
        my($pm) = @_;
        warn 'called';
        $cv->send;
    },
);
$cv->recv;
warn 'end';
