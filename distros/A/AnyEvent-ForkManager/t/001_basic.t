#!perl -w
use strict;
use Test::More;
use Test::SharedFork;

use AnyEvent;
use AnyEvent::ForkManager;

my $MAX_WORKERS = 2;
my $JOB_COUNT   = $MAX_WORKERS * 3;
my $TEST_COUNT  =
    ($JOB_COUNT)     + # in child process tests
    ($JOB_COUNT * 2) + # on_start
    ($JOB_COUNT * 3) + # on_finish
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_enqueue
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_dequeue
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_working_max
    3;# wait_all_children
plan tests => $TEST_COUNT;

my $pm = AnyEvent::ForkManager->new(
    max_workers => $MAX_WORKERS,
    on_start    => sub{
        my($pm, $pid, $exit_code) = @_;

        note 'start on_start';
        cmp_ok $pm->num_workers, '<', $pm->max_workers, 'not working max';
        is $$, $pm->manager_pid, 'called by manager';
        note 'end   on_start';
    },
    on_finish => sub{
        my($pm, $pid, $status, $exit_code) = @_;

        note 'start on_finish';
        is $status >> 8, $exit_code, 'status';
        cmp_ok $pm->num_workers, '<', $pm->max_workers, 'not working max';
        is $$, $pm->manager_pid, 'called by manager';
        note 'end   on_finish';
    },
    on_enqueue => sub{
        my($pm, $exit_code) = @_;

        note 'start on_enqueue';
        is $pm->num_workers, $pm->max_workers, 'working max';
        is $$, $pm->manager_pid, 'called by manager';
        note 'end   on_start';
    },
    on_dequeue => sub{
        my($pm, $exit_code) = @_;

        note 'start on_dequeue';
        cmp_ok $pm->num_workers, '<', $pm->max_workers, 'not working max';
        is $$, $pm->manager_pid, 'called by manager';
        note 'end   on_dequeue';
    },
    on_working_max => sub{
        my($pm, $exit_code) = @_;

        note 'start on_working_max';
        is $pm->num_workers, $pm->max_workers, 'working max';
        is $$, $pm->manager_pid, 'called by manager';
        note 'end   on_working_max';
    }
);

my $cv = AnyEvent->condvar;

my @all_data = (1 .. $JOB_COUNT);
my $started_all_process = 0;
foreach my $exit_code (@all_data) {
    $pm->start(
        cb => sub {
            my($pm, $exit_code) = @_;
            local $SIG{INT} = sub { $started_all_process = 1; };
            isnt $$, $pm->manager_pid, 'called by child';
            until ($started_all_process) {}; # wait
            note "exit_code: $exit_code";
            $pm->finish($exit_code);
            fail 'finish failed';
        },
        args => [$exit_code]
    );
}
$started_all_process = 1;
$pm->signal_all_children('INT');

$pm->wait_all_children(
    cb => sub {
        my($pm) = @_;
        note 'start wait_all_children callback';
        is $$, $pm->manager_pid, 'called by manager';
        is $pm->num_workers, 0, 'finished all child process';
        is $pm->num_queues,  0, 'empty all child process queue';
        note 'end   wait_all_children callback';
        $cv->send;
    },
);

$cv->recv;
