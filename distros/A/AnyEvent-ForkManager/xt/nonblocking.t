#!perl -w
use strict;
use Test::More;
use Test::SharedFork;
use Test::SharedObject;

use AnyEvent;
use AnyEvent::ForkManager;
use Time::HiRes;

my $MAX_WORKERS = 4;
my $JOB_COUNT   = $MAX_WORKERS * 5;
my $TEST_COUNT  =
    ($JOB_COUNT)     + # in child process tests
    ($JOB_COUNT)     + # start method is non-blocking tests
    ($JOB_COUNT * 2) + # on_start
    ($JOB_COUNT * 3) + # on_finish
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_enqueue
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_dequeue
    ($JOB_COUNT > $MAX_WORKERS ? (($JOB_COUNT - $MAX_WORKERS) * 2) : 0) + # on_working_max
    5;# wait_all_children
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

my $ready = Test::SharedObject->new(0);

my @all_data = (1 .. $JOB_COUNT);
my $started_all_process = 0;
foreach my $exit_code (@all_data) {
    Time::HiRes::sleep(0.07);
    my $start_time = Time::HiRes::gettimeofday;
    $pm->start(
        cb => sub {
            my($pm, $exit_code) = @_;
            Time::HiRes::sleep(0.5);
            isnt $$, $pm->manager_pid, 'called by child';

            Time::HiRes::usleep(100) until $ready->get();

            $pm->finish($exit_code);
            fail 'finish failed';
        },
        args => [$exit_code]
    );
    my $end_time = Time::HiRes::gettimeofday;
    cmp_ok $end_time - $start_time, '<', 0.3, 'non-blocking';
}
$ready->set(1);

my $callback_called;
my $start_time = Time::HiRes::gettimeofday;
$pm->wait_all_children(
    cb => sub {
        my($pm) = @_;
        note 'start wait_all_children callback';
        is $$, $pm->manager_pid, 'called by manager';
        is $pm->num_workers, 0, 'finished all child process';
        is $pm->num_queues,  0, 'empty all child process queue';
        note 'end   wait_all_children callback';
        $callback_called++;
        $cv->send;
    },
);
my $end_time = Time::HiRes::gettimeofday;
cmp_ok $end_time - $start_time, '<', 0.1, 'non-blocking';

$cv->recv;
is $callback_called, 1, 'wait_all_children callback is called at once';
