use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use Time::HiRes qw[time];
$|++;
Acme::Parataxis::run(
    sub {
        my $start_time = time();
        diag "Starting parallel sleeps at $start_time...";

        # Check thread pool size
        my $pool_size = Acme::Parataxis::get_thread_pool_size();
        diag "Detected thread pool size: $pool_size";

        # Spawn only as many tasks as we have threads (up to 3) to ensure they run in parallel.
        # If pool size is 2, running 3 tasks takes 2 seconds, failing the 1.8s test.
        my $num_tasks = $pool_size;
        $num_tasks = 3 if $num_tasks > 3;
        $num_tasks = 1 if $num_tasks < 1;
        diag "Spawning $num_tasks parallel tasks...";
        my @futures;
        for my $i ( 1 .. $num_tasks ) {
            push @futures, Acme::Parataxis->spawn(
                sub {
                    my $id = $i;    # Closure capture
                    diag "Fiber $id started (FID: " . Acme::Parataxis->current_fid . ')';
                    diag "Fiber $id: Sleeping for 1000ms...";
                    Acme::Parataxis->await_sleep(1000);
                    diag "Fiber $id: Woke up!";
                    return $id;
                }
            );
        }

        # Wait for all
        diag "Main: Waiting for $num_tasks fibers to finish...";
        my @results;
        push @results, $_->await() for @futures;
        my $elapsed = time() - $start_time;
        diag "Total wallclock time: $elapsed seconds";
        diag 'Results: ' . join( ', ', @results );
        my $expected = [ 1 .. $num_tasks ];
        is \@results, $expected, 'Fibers returned correct individual results';

        # If we have at least 1 task, it should take ~1s.
        ok $elapsed < 1.8, "$num_tasks tasks ran in parallel (elapsed < 1.8s)";
    }
);
done_testing();
