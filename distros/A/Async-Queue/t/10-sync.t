use strict;
use warnings;
use Test::More;
use Test::Builder;

BEGIN {
    use_ok("Async::Queue");
}

sub checkQueue {
    my ($q, $exp_length, $exp_running, $exp_concurrency) = @_;
    local $Test::Builder::Level += 1;
    is($q->length, $exp_length, "length is $exp_length") if defined $exp_length;
    is($q->waiting, $q->length, "waiting is the same as length");
    is($q->running, $exp_running, "running is $exp_running") if defined $exp_running;
    is($q->concurrency, $exp_concurrency, "concurrency is $exp_concurrency") if defined $exp_concurrency;
}

{
    note('--- worker arguments');
    my $got_task = '';
    my $q; $q = new_ok('Async::Queue', [ concurrency => 1, worker => sub {
        my ($task, $cb, $queue) = @_;
        $got_task = $task;
        is(ref($cb), "CODE", 'cb is a coderef');
        is($queue, $q, 'queue is the object q');
    } ]);
    $q->push('a');
    is($got_task, 'a', 'worker executed');
}

{
    note('--- basic push() behavior');
    my @results = ();
    my $q = new_ok('Async::Queue', [ concurrency => 1, worker => sub {
        my ($task, $cb) = @_;
        push(@results, $task);
        $cb->(lc($task), uc($task));
    }]);
    checkQueue $q, 0, 0, 1;
    is($q->push("a"), $q, 'push() method returns the object.');
    checkQueue $q, 0, 0, 1;
    is_deeply(\@results, ["a"], "results ok");
    @results = ();
    foreach my $letter (qw(b c d)) {
        $q->push($letter);
        checkQueue $q, 0, 0, 1;
    }
    is_deeply(\@results, [qw(b c d)], "results OK");

    note('--- callback to push()');
    @results = ();
    is($q->push("E", sub {
        my @args = @_;
        push(@results, @args);
        checkQueue $q, 0, 1, 1;
    }), $q, 'push() method returns the object.');
    is_deeply(\@results, [qw(E e E)], "results OK. push() callback is called with arguments");
}

{
    note('--- accessors');
    my $worker = sub { };
    my $q = new_ok('Async::Queue', [concurrency => 12, worker => $worker]);
    checkQueue $q, 0, 0, 12;
    is($q->concurrency(5), 5, "set concurrency to 5");
    checkQueue $q, 0, 0, 5;
    is($q->worker, $worker, "worker() returns coderef");
    ok(!defined($q->$_), "$_() returns undef now.") foreach qw(saturated empty drain);
    my $another_worker = sub { print "hoge" };
    my %handlers = map { $_ => sub { print $_ } } qw(saturated empty drain);
    is($q->worker($another_worker), $another_worker, "set another_worker");
    is($q->$_($handlers{$_}), $handlers{$_}, "set $_ hander") foreach keys %handlers;
    is($q->worker, $another_worker, "get another_worker");
    is($q->$_(), $handlers{$_}, "get $_ handler") foreach keys %handlers;
    ok(!defined($q->$_(undef)), "set $_ handler to undef") foreach keys %handlers;
}

{
    note('--- event callbacks receive the object as the first argument');
    my @results = ();
    my $q; $q = new_ok('Async::Queue', [
        concurrency => 1, worker => sub {
            my ($task, $cb) = @_;
            push(@results, $task);
            $cb->(uc($task));
        },
        map { my $event = $_; $event => sub {
            my ($aq) = @_;
            is($aq, $q, "\"$event\" event handler receives the object.");
            push(@results, $event);
        } } qw(saturated empty drain)
    ]);
    $q->push("task", sub {
        my ($ret) = @_;
        push(@results, $ret, "finish");
    });
    is_deeply(\@results, [qw(saturated empty task TASK finish drain)], "results OK. all events are fired.");
}

{
    note('--- default concurrency');
    my $q = new_ok('Async::Queue', [worker => sub {}]);
    is($q->concurrency, 1, "concurrency is 1 by default.");
    $q = new_ok('Async::Queue', [ worker => sub {}, concurrency => undef ]);
    is($q->concurrency, 1, "concurrency is 1 by default.");
    $q->concurrency(3);
    is($q->concurrency, 3, "concurrency changed to 3.");
    is($q->concurrency(undef), 1, "concurrency changed to the default, which is 1.");
    is($q->concurrency, 1, "concurrency is 1.");
}


done_testing();
