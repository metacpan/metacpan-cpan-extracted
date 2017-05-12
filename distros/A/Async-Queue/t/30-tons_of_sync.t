use strict;
use warnings;
use Test::More;

use Async::Queue;

sub stack_frame_num {
    my $num = 0;
    while(caller($num)) {
        $num++;
    }
    return $num;
}

my $done_callback;
my $stack_frame_threshold = 800;
my $stack_frame_checked = 0;
my $task_num = 1000;
my $task_executed = 0;
my $q = Async::Queue->new(
    concurrency => 1,
    worker => sub {
        my ($task, $callback) = @_;
        $task_executed++;
        if($task_executed == $task_num) {
            $stack_frame_checked = 1;
            cmp_ok(stack_frame_num(), "<", $stack_frame_threshold, "sync worker should not push too many stack frames");
        }
        if(defined($done_callback)) {
            $callback->($task);
        }else {
            $done_callback = sub {
                $callback->($task);
            };
        }
    }
);

foreach my $with_finish_callback (0, 1) {
    note("--- with_finish_callback: $with_finish_callback");
    undef $done_callback;
    $stack_frame_checked = 0;
    $task_executed = 0;
    my @finish_result = ();
    if($with_finish_callback) {
        my $finish_callback = sub {
            my ($result) = @_;
            push(@finish_result, $result);
        };
        $q->push($_, $finish_callback) foreach 1 .. $task_num;
    }else {
        $q->push($_) foreach 1 .. $task_num;
    }
    ok(defined($done_callback), 'got done_callback');
    is($q->running(), 1, "1 running");
    is($q->waiting(), $task_num - 1, ($task_num - 1)." waiting");
    $done_callback->();
    ok($stack_frame_checked, 'stack frame checked');
    is($q->running(), 0, "no running");
    is($q->waiting(), 0, "no waiting");
    if($with_finish_callback) {
        is_deeply(\@finish_result, [1..$task_num], "finish result OK");
    }
}

done_testing();





