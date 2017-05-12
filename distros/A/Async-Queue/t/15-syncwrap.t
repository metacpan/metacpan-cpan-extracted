use strict;
use warnings;
use FindBin;
use lib ("$FindBin::RealBin/lib");
use Test::More;

BEGIN {
    use_ok('Test::AQWrapper');
}

sub showResults {
    diag("results: ". join(" ", @_));
}

{
    my @results = ();
    my $q; $q = new_ok('Test::AQWrapper', [concurrency => 1, worker => sub {
        my ($task, $cb) = @_;
        $q->check();
        push(@results, $task);
        $cb->(uc($task));
    }]);
    $q->saturated(sub {
        $q->check();
        push(@results, "S");
    });
    $q->empty(sub {
        $q->check();
        push(@results, "E");
    });
    $q->drain(sub {
        $q->check();
        push(@results, "D");
    });

    note('--- event callbacks: local specs');
    @results = ();
    $q->clearCounter();
    $q->push('a', sub { $q->finish });
    is_deeply(\@results, [qw(S E a D)], '"saturated" before "empty".');
    @results = ();
    $q->push('b', sub { $q->finish });
    is_deeply(\@results, [qw(S E b D)], 'every task goes into the queue first. "empty" fires even if the task is served immediately.');
    $q->check(0, 0, 2, 2);


    note('--- event callbacks (concurrency 1)');
    @results = ();
    $q->clearCounter();
    $q->push($_, sub { $q->check(); push(@results, @_); $q->finish }) foreach qw(a b c);
    is_deeply(\@results, [qw(S E a A D S E b B D S E c C D)], "results OK.") or
        showResults(@results);
    $q->check(0, 0, 3, 3);
    

    note('--- event callbacks (concurrency 3)');
    @results = ();
    $q->clearCounter();
    $q->concurrency(3);
    $q->push($_, sub { $q->check(); push(@results, @_); $q->finish }) foreach qw(w x y z);
    is_deeply(\@results, [qw(E w W D E x X D E y Y D E z Z D)], "results OK") or
        showResults(@results);
    $q->check(0, 0, 4, 4);

    note('--- push inside finish callbacks (concurrency 1)');
    @results = ();
    $q->clearCounter();
    $q->concurrency(1);
    $q->push('a', sub {
        $q->check(0, 1, 0, 1);
        $q->push('b', sub {
            $q->check(1, 1, 1, 3);
            $q->push('d', sub {
                $q->check(0, 1, 3, 4);
                $q->finish;
            });
            $q->finish;
        });
        $q->push('c', sub {
            $q->check(1, 1, 2, 4);
            $q->finish;
        });
        $q->finish;
    });
    is_deeply(\@results, [qw(S E a b c E d D)], '"saturated" fires only when "running" increases to the max.') or
        showResults(@results);
    $q->check(0, 0, 4, 4);

    note('--- push inside finish callbacks (concurrency 3)');
    @results = ();
    $q->clearCounter();
    $q->concurrency(3);
    $q->push('a', sub {
        $q->check(0, 1, 0, 1);
        $q->push('b', sub {
            $q->check(0, 2, 0, 2);
            $q->push('c', sub {
                $q->check(0, 3, 0, 3);
                $q->push('d', sub {
                    $q->check(2, 3, 1, 6);
                    $q->finish;
                });
                $q->push('e', sub {
                    $q->check(1, 3, 2, 6);
                    $q->finish;
                });
                $q->push("f", sub {
                    $q->check(0, 3, 3, 6);
                    $q->finish;
                });
                $q->finish;
            });
            $q->push('g', sub {
                $q->check(0, 3, 4, 7);
                $q->push('h', sub {
                    $q->check(0, 3, 5, 8);
                    $q->push('i', sub {
                        $q->check(0, 3, 6, 9);
                        $q->finish;
                    });
                    $q->finish;
                });
                $q->finish;
            });
            $q->finish;
        });
        $q->finish;
    });
    is_deeply(\@results, [qw(E a E b S E c d e E f S E g E h E i D)]) or
        showResults(@results);
    $q->check(0, 0, 9, 9);

    note('--- "empty" event keeps firing until its "saturated"');
    $q->concurrency(3);
    $q->clearCounter;
    @results = ();
    $q->push("a", sub {
        $q->push("b", sub {
            $q->push("c", sub {
                $q->push($_, sub { $q->finish }) foreach qw(d e f g);
                $q->finish;
            });
            $q->finish;
        });
        $q->finish;
    });
    is_deeply(\@results, [qw(E a E b S E c d e f E g D)],
              'results OK. "empty" event keeps firing until "saturated"') or
                  showResults(@results);
}

{
    note('--- push from the worker (concurrency 1)');
    my @results = ();
    my @tasks = qw(a b c d e f);
    my $q;
    my $shiftPush = sub {
        my $t = shift(@tasks);
        $q->push($t, sub { $q->finish }) if defined $t;
    };
    $q = new_ok('Test::AQWrapper', [
        concurrency => 1,
        worker => sub {
            my ($task, $cb) = @_;
            $q->check;
            push(@results, $task);
            $shiftPush->();
            $cb->();
        },
        saturated => sub { $q->check; push(@results, "S") },
        empty => sub { $q->check; push(@results, "E") },
        drain => sub { $q->check; push(@results, "D") },
    ]);
    $q->clearCounter();
    $q->push(shift(@tasks), sub { $q->finish });
    $q->check(0, 0, 6, 6);
    is_deeply(\@results, [qw(S E a E b E c E d E e E f D)],
              'results OK. No "saturated" event except for the beginning.') or
                  showResults(@results);

    
    note('--- push from the worker (concurrency 3)');
    $q->concurrency(3);
    @results = ();
    @tasks = 1..6;
    $q->clearCounter();
    $q->push(shift(@tasks), sub { $q->finish });
    $q->check(0, 0, 6, 6);
    is_deeply(\@results, [qw(E 1 E 2 S E 3 E 4 E 5 E 6 D)]) or
        showResults(@results);
    

    note('--- push in "empty" event (concurrency 1)');
    $q->concurrency(1);
    $q->worker(sub {
        my ($task, $cb) = @_;
        $q->check;
        push(@results, $task);
        $cb->();
    });
    $q->empty(sub {
        $q->check;
        push(@results, "E");
        $shiftPush->();
    });
    $q->clearCounter;
    @results = ();
    @tasks = 1..5;
    $q->push(shift(@tasks), sub { $q->finish });
    $q->check(0, 0, 5, 5);
    is_deeply(\@results, [qw(S E 1 E 2 E 3 E 4 E 5 D)], "results OK") or
        showResults(@results);

    note('--- push in "empty" event (concurrency 3)');
    $q->concurrency(3);
    $q->clearCounter;
    @results = ();
    @tasks = 1..6;
    $q->push(shift(@tasks), sub { $q->finish });
    $q->check(0, 0, 6, 6);
    is_deeply(\@results, [qw(E E S E 3 E 4 E 5 E 6 2 1 D)], 'early tasks filling the service quit last.') or
        showResults(@results);

    note('--- push in "saturated" event (concurrency 1)');
    $q->empty(sub { $q->check; push(@results, "E") });
    $q->saturated(sub {
        $q->check;
        push(@results, "S");
        $shiftPush->();
    });
    $q->concurrency(1);
    $q->clearCounter;
    @results = ();
    @tasks = 1..9;
    $q->push(shift(@tasks), sub { $q->finish });
    $q->check(0, 0, 2, 2);
    is_deeply(\@results, [qw(S 1 E 2 D)], '"saturated" event does not repeat.') or
        showResults(@results);

    note('--- push in "saturated" event (concurrency 3)');
    $q->concurrency(3);
    $q->clearCounter;
    @results = ();
    @tasks = 1..9;
    $q->push(shift(@tasks), sub {
        $q->check(0, 1, 0, 1);
        $q->push(shift(@tasks), sub {
            $q->check(0, 2, 0, 2);
            $q->push(shift(@tasks), sub {
                $q->check(1, 3, 0, 4);
                $q->finish;
            });
            $q->finish;
        });
        $q->finish;
    });
    $q->check(0, 0, 4, 4);
    is_deeply(\@results, [qw(E 1 E 2 S 3 E 4 D)],
              '"empty" does not fire before 3 because "saturated" event populates 4.') or
                  showResults(@results);

    note('--- push in "drain" event (concurrency 1)');
    $q->saturated(sub { $q->check; push(@results, "S") });
    $q->drain(sub {
        $q->check;
        push(@results, "D");
        $shiftPush->();
    });
    $q->concurrency(1);
    $q->clearCounter;
    @results = ();
    @tasks = 1..3;
    $q->push(shift(@tasks), sub { $q->finish });
    $q->check(0, 0, 3, 3);
    is_deeply(\@results, [qw(S E 1 D S E 2 D S E 3 D)], 'results OK. "drain" feeds the queue with tasks.') or
        showResults(@results);


    note('--- push in "drain" event (concurrency 3)');
    $q->concurrency(3);
    $q->clearCounter;
    @results = ();
    @tasks = 1..7;
    $q->push(shift(@tasks), sub {
        $q->check(0, 1, 0, 1);
        $q->push(shift(@tasks), sub {
            $q->check(0, 2, 0, 2);
            $q->push(shift(@tasks), sub {
                $q->check(0, 3, 0, 3);
                $q->push(shift(@tasks), sub {
                    $q->check(0, 3, 1, 4);
                    $q->finish;
                });
                $q->finish;
            });
            $q->finish;
        });
        $q->finish;
    });
    $q->check(0, 0, 7, 7);
    is_deeply(\@results, [qw(E 1 E 2 S E 3 E 4 D E 5 D E 6 D E 7 D)], 'results OK.') or
        showResults(@results);
}

{
    note('--- infinite concurrency');
    foreach my $conc_val (0, -10) {
        my @results = ();
        my $q; $q = new_ok('Test::AQWrapper', [
            concurrency => $conc_val, worker => sub {
                my ($task, $cb) = @_;
                $q->check;
                push(@results, $task);
                $cb->();
            },
            map { my $e = $_; $e => sub {
                $q->check;
                push(@results, $e);
            } } qw(saturated empty drain)
        ]);
        is($q->concurrency, $conc_val, "concurrency is $conc_val, meaning infinite concurrency.");
        
        my @tasks = (1 .. 15);
        my @orig_tasks = @tasks;
        my $finish_cb; $finish_cb = sub {
            my $t = shift(@tasks);
            $q->push($t, $finish_cb) if defined $t;
            $q->finish;
        };
        $q->push(shift(@tasks), $finish_cb);
        $q->check(0, 0, int(@orig_tasks), int(@orig_tasks));
        is_deeply(\@results, [(map { ("empty", $_) } @orig_tasks), "drain"],
              'results OK. Never saturated.') or
                  showResults(@results);
    }
}

done_testing();

