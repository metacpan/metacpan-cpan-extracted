use v5.40;
use blib;
use Acme::Parataxis qw[:all];
use Time::HiRes     qw[time];

# Stress Test 1: High Fiber Count & Rapid Lifecycle
# This tests the scheduler's ability to handle many short-lived fibers.
async {
    my $total_fibers = 1000;    # Fits the default 1024-entry table; max_fibers defaults to 65536
    my $iterations   = 5;
    say "Starting Stress Test: $total_fibers fibers, $iterations iterations...";
    my $start_time = time();
    for my $iter ( 1 .. $iterations ) {
        my $iter_start = time();
        my @futures;

        # Spawn a batch of fibers
        for my $i ( 1 .. $total_fibers ) {
            push @futures, fiber {

                # Do a tiny bit of work
                my $val = 0;
                $val += $_ for 1 .. 100;
                no warnings 'recursion';
                yield() if $i % 2 == 0;    # Mix in some yields
                return $val;
            };
        }

        # Wait for all to finish
        for my $f (@futures) {
            await $f;
        }
        my $elapsed = time() - $iter_start;
        say sprintf '  Iteration %2d completed in %.4fs', $iter, $elapsed;
    }
    my $total_elapsed = time() - $start_time;
    say sprintf 'Total time for %d fibers across %d iterations: %.4fs', $total_fibers, $iterations, $total_elapsed;
    say 'Average time per fiber lifecycle: ' . ( $total_elapsed / ( $total_fibers * $iterations ) ) . 's';
};
