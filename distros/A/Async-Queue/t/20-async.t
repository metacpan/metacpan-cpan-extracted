use strict;
use warnings;
use FindBin;
use lib ("$FindBin::RealBin/lib");
use Test::More;
use Test::AQWrapper;
use Test::Exception;

my %deferred_results = ();
my @results = ();

sub createQueue {
    my ($concurrency) = @_;
    my $q = Test::AQWrapper->new(
        worker => sub {
            my ($task, $cb) = @_;
            die "$task is already executed." if exists $deferred_results{$task};
            push(@results, "s$task");
            $deferred_results{$task} = $cb;
        },
        concurrency => $concurrency,
        map { my $e = $_; $e => sub {
            push(@results, uc(substr($e, 0, 1)));
        } } qw(saturated empty drain)
     );
    return $q;
}

sub finishTask {
    my ($task) = @_;
    die "$task is not executed." if not exists $deferred_results{$task};
    my $cb = $deferred_results{$task};
    delete $deferred_results{$task};
    push(@results, "e$task");
    $cb->();
}

{
    my $q;
    note('--- concurrency 1');
    $q = createQueue(1);
    @results = ();
    $q->push($_, sub { $q->finish }) foreach 1..5;
    $q->check(4, 1, 0, 5);
    throws_ok { finishTask(3) } qr/not executed/i, "task 3 is still in the queue.";
    finishTask(1);
    $q->check(3, 1, 1, 5);
    finishTask(2);
    $q->check(2, 1, 2, 5);
    finishTask(3);
    $q->check(1, 1, 3, 5);
    finishTask(4);
    $q->check(0, 1, 4, 5);
    finishTask(5);
    $q->check(0, 0, 5, 5);
    is_deeply(\@results, [qw(S E s1 e1 s2 e2 s3 e3 s4 e4 E s5 e5 D)], "results OK");

    note('--- concurrency 3');
    $q->concurrency(3);
    $q->clearCounter;
    @results = ();
    $q->push($_, sub { $q->finish }) foreach 1..5;
    $q->check(2, 3, 0, 5);
    finishTask(2);
    $q->check(1, 3, 1, 5);
    finishTask(1);
    $q->check(0, 3, 2, 5);
    $q->push($_, sub { $q->finish }) foreach 6..8;
    $q->check(3, 3, 2, 8);
    finishTask(3);
    $q->check(2, 3, 3, 8);
    finishTask(6);
    $q->check(1, 3, 4, 8);
    finishTask(5);
    $q->check(0, 3, 5, 8);
    finishTask(7);
    $q->check(0, 2, 6, 8);
    finishTask(8);
    $q->check(0, 1, 7, 8);
    $q->push($_, sub { $q->finish }) foreach (9, 10);
    $q->check(0, 3, 7, 10);
    finishTask(9);
    $q->check(0, 2, 8, 10);
    finishTask(4);
    $q->check(0, 1, 9, 10);
    finishTask(10);
    $q->check(0, 0, 10, 10);
    is_deeply(\@results, [qw(E s1 E s2 S E s3 e2 s4 e1 E s5 e3 s6 e6 s7 e5 E s8 e7 e8 E s9 S E s10 e9 e4 e10 D)], "results OK");

    {
        note("--- concurrency infinite");
        my $total = 10;
        $q->concurrency(0);
        $q->clearCounter;
        @results = ();
        $q->push($_, sub { $q->finish }) foreach 1..$total;
        
        my $done_num = 0;
        foreach my $fin (5, 2, 3, 7, 10, 1, 9, 8, 6, 4) {
            $q->check(0, $total - $done_num, $done_num, $total);
            finishTask($fin);
            $done_num++;
        }
        $q->check(0, 0, $total, $total);
        is_deeply(\@results, [qw(E s1 E s2 E s3 E s4 E s5 E s6 E s7 E s8 E s9 E s10 e5 e2 e3 e7 e10 e1 e9 e8 e6 e4 D)], "results OK");
    }
}


done_testing();




