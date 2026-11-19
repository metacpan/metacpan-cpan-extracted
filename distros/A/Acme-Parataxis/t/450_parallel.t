use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
use Time::HiRes qw[time];
$|++;
#
Acme::Parataxis::run(
    sub {
        my $pool_size = Acme::Parataxis::get_thread_pool_size();
        diag "Detected thread pool size: $pool_size";

        # Spawn only as many tasks as there are workers (capped at 3). A pool of one is still a valid smoke host.
        my $num_tasks = $pool_size > 3 ? 3 : ( $pool_size < 1 ? 1 : $pool_size );
        diag "Spawning $num_tasks parallel tasks...";
        my @intervals;
        my @futures;
        my $wall_start = time();
        for my $i ( 1 .. $num_tasks ) {
            my $id = $i;    # Per-iteration lexical, so every closure keeps its own id.
            push @futures, Acme::Parataxis->spawn(
                sub {
                    diag "Fiber $id started (FID: " . Acme::Parataxis->current_fid . ')';
                    my $started = time();
                    diag "Fiber $id: Sleeping for 1000ms...";
                    Acme::Parataxis->await_sleep(1000);
                    my $finished = time();
                    push @intervals, [ $started, $finished ];
                    diag "Fiber $id: Woke up!";
                    return $id;
                }
            );
        }

        # Every spawn() runs its fiber up to the park point, so all sleeps should be queued before the first await.
        is Acme::Parataxis::get_outstanding_jobs(), $num_tasks, 'all sleeps are in the native queue before the first await';
        my @results;
        push @results, $_->await() for @futures;
        my $elapsed = time() - $wall_start;
        diag "Total wallclock time: $elapsed seconds";
        diag 'Results: ' . join( ', ', @results );
        is \@results, [ 1 .. $num_tasks ], 'Fibers returned correct individual results';

        # Total elapsed time alone cannot prove overlap: setup and scheduler latency on a loaded smoker can inflate it.
        # Compare the actual sleep windows instead, which is what "parallel" means here.
        if ( $num_tasks > 1 ) {
            my $latest_start = 0;
            my $earliest_finish;
            for my $interval (@intervals) {
                my ( $start, $finish ) = @$interval;
                $latest_start    = $start  if $start > $latest_start;
                $earliest_finish = $finish if !defined($earliest_finish) || $finish < $earliest_finish;
            }
            my $overlap = $earliest_finish - $latest_start;
            diag 'Sleep overlap: ' . sprintf( '%.3f', $overlap ) . ' seconds';
            ok $overlap > 0.25, 'sleep windows overlapped by more than 250ms';
        }
        else {
            pass 'single-worker pool: overlap assertion not applicable';
        }

        # Generous sanity bound: catches pathological serial execution without failing on a busy smoker.
        ok $elapsed < 2.6, "$num_tasks tasks finished within 2.6s";
    }
);
#
done_testing();
