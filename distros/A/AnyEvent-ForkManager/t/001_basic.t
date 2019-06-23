#!perl -w
use strict;
use Test::More 0.98;
use Test::SharedFork 0.31;
use Test::SharedObject;

use AnyEvent;
use AnyEvent::ForkManager;
use Time::HiRes;

my $MAX_WORKERS = 2;
my $JOB_COUNT   = $MAX_WORKERS * 3;
my $TEST_COUNT  =
    ($JOB_COUNT)     + # in child process tests
    ($JOB_COUNT * 2) + # on_start
    ($JOB_COUNT * 3) + # on_finish
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_enqueue
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_dequeue
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_working_max
    4;# wait_all_children
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


my $ready = Test::SharedObject->new(0);

my @all_data = (1 .. $JOB_COUNT);
my $started_all_process = 0;
foreach my $exit_code (@all_data) {
    $pm->start(
        cb => sub {
            my($pm, $exit_code) = @_;
            isnt $$, $pm->manager_pid, 'called by child';

            Time::HiRes::usleep(100) until $ready->get();

            note "exit_code: $exit_code";
            $pm->finish($exit_code);
            fail 'finish failed';
        },
        args => [$exit_code]
    );
}
$ready->set(1);

my $cv = AnyEvent->condvar;

my $callback_called;
$callback_called++;
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
is $callback_called, 1, 'wait_all_children callback is called at once';
