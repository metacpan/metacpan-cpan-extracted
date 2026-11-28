use v5.40;
use blib;
use Acme::Parataxis qw[:all];
use Time::HiRes     qw[time];

# Stress Test 3: Preemption and Deep Call Stacks
# This tests the integrity of the stack teleportation during deep recursion
# and the effectiveness of the preemption threshold.
# Configuration
my $recursion_depth = 50;     # Modest depth; fiber C-stack size is platform-dependent (2/8/64 MiB)
my $preempt_at      = 100;    # maybe_yield() calls before a forced yield
my $num_fibers      = 10;     # Number of competing CPU-bound fibers
Acme::Parataxis::set_preempt_threshold($preempt_at);
async {
    say 'Starting Preemption Stress Test...';
    say "Recursion depth: $recursion_depth, Preempt threshold: $preempt_at, Fibers: $num_fibers";
    my $start_time = time();
    my @futures;

    # Recursive function to stress pads and preemption
    sub recursive_math( $depth_in, $fiber_id ) {
        no warnings 'uninitialized';
        my $depth = $depth_in;    # Localize
        return 1 if $depth <= 0;

        # Do some CPU work and potential preemption
        my $acc = 0;
        for ( 1 .. 100 ) {
            $acc += $_;
            maybe_yield();    # Signal to the scheduler
        }

        # Recurse and capture in a local variable immediately
        my $sub_result = recursive_math( $depth - 1, $fiber_id );
        my $result     = $sub_result + $acc;

        # Another preemption check after coming back up the stack
        maybe_yield();
        return $result;
    }

    # Spawn competing CPU-bound recursive fibers
    for my $i ( 1 .. $num_fibers ) {
        push @futures, fiber {
            say "  [Fiber $i] Starting deep recursion...";
            my $val = recursive_math( $recursion_depth, $i );
            say "  [Fiber $i] Done with result: $val";
            return $val;
        };
    }

    # Wait for all to finish
    for my $f (@futures) {
        await $f;
    }
    my $total_elapsed = time() - $start_time;
    say sprintf 'Total time for %d competing recursive fibers: %.4fs', $num_fibers, $total_elapsed;

    # Reset preemption threshold for the rest of the script/environment
    Acme::Parataxis::set_preempt_threshold(0);
};
