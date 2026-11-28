use v5.40;
use blib;
use Acme::Parataxis qw[:all];
use Time::HiRes     qw[time];
$|++;

# Stress Test 2: Concurrent I/O (Background Thread Pool)
# This tests the ability to handle many simultaneous blocking background tasks.
async {
    my $concurrency = 64;    # Concurrent sleepers; the native pool grows up to 64 threads
    my $iterations  = 5;
    my $sleep_ms    = 500;
    say "Starting I/O Stress Test: $concurrency concurrent sleeps of ${sleep_ms}ms...";
    my $start_time = time();
    for my $iter ( 1 .. $iterations ) {
        my $iter_start = time();
        my @futures;

        # Spawn concurrent sleep fibers
        for my $i ( 1 .. $concurrency ) {
            push @futures, fiber {
                no warnings 'recursion';

                # This offloads to the C-level background thread pool
                await_sleep($sleep_ms);
                return "Worker $i done";
            };
        }

        # Wait for all to finish
        for my $f (@futures) {
            await $f;
        }
        my $elapsed = time() - $iter_start;

        # Since they are concurrent and $concurrency > CPU count (usually),
        # it should take roughly (ceil(concurrency / num_cpus) * sleep_ms)
        say sprintf '  Iteration %2d completed in %.4fs', $iter, $elapsed;
    }
    my $total_elapsed = time() - $start_time;
    say sprintf 'Total time for %d concurrent sleeps across %d iterations: %.4fs', $concurrency, $iterations, $total_elapsed;
};
