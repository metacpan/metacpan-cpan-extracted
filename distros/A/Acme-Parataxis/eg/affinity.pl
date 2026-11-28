use v5.40;
use blib;
use Acme::Parataxis qw[:all];
$|++;

# Demonstrate Thread Affinity / Core ID using modern API
async {
    say 'Main thread (TID: ' . tid() . ')';
    my @futures;
    for ( 1 .. 20 ) {
        push @futures, fiber {

            # await_core_id() offloads to the pool and returns the core ID
            return await_core_id();
        };
    }
    say 'Main: Tasks spawned, waiting for results...';
    my %distribution;
    for my $f (@futures) {
        my $core = await $f;
        if ( defined $core && $core >= 0 ) {
            $distribution{$core}++;
        }
        else {
            warn "Failed to get core ID for a task.\n";
        }
    }
    say 'Background Task Distribution across CPU Cores:';
    for my $core ( sort { $a <=> $b } keys %distribution ) {
        say "  Core $core: " . $distribution{$core} . ' tasks';
    }

    # Explicitly clear futures to break any potentially clobbered references
    # during teardown in some Perl builds
    @futures = ();
};
