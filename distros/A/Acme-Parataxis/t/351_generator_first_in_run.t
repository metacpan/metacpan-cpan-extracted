use v5.40;
use blib;
use Acme::Parataxis qw[async fiber nursery yield];
use Acme::Parataxis::Generator;
use Test2::V1 -ipP;
$|++;

# The first generator a process ever builds is built here from inside a run. That case used to wedge the
# process: reserving fid 0 (a Windows workaround, see Generator.pm) parked a fiber for the lifetime of the
# process, and a fiber born *during* a run is not in the run's %PRESET_FIBERS snapshot, so the run's
# deadlock detector counted it as live run work and killed the process as that run ended - after correct
# output. A run's own main fiber already holds fid 0 before the body executes, so no reserved fiber is
# needed here and none is created.
subtest 'the first generator in a process, built inside a run, does not wedge the run' => sub {
    my @collected;
    my $fid;
    async {
        my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 1 .. 3 } );
        $fid = $gen->fiber->fid;
        while ( defined( my $v = $gen->next ) ) { push @collected, $v }
    };
    is "@collected", '1 2 3', 'every value arrived';
    ok $fid >= 1, "the generator's fiber is not fid 0 (fid $fid)";
    is Acme::Parataxis::get_live_fiber_count(), 0, 'no fiber was parked permanently';
};
subtest 'a later run can build and pull a generator too' => sub {
    my @collected;
    async {
        my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 'x' .. 'z' } );
        while ( defined( my $v = $gen->next ) ) { push @collected, $v }
    };
    is "@collected",                            'x y z', 'every value arrived';
    is Acme::Parataxis::get_live_fiber_count(), 0,       'still nothing parked permanently';
};
subtest 'the first generator in a run, pulled from a spawned child fiber' => sub {
    my @collected;
    my $done = 0;
    async {
        my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 1 .. 3 } );
        fiber {
            while ( defined( my $v = $gen->next ) ) { push @collected, $v }
            $done = 1;
        };
        yield until $done;
    };
    is "@collected",                            '1 2 3', 'the child fiber pulled every value';
    is Acme::Parataxis::get_live_fiber_count(), 0,       'nothing parked permanently';
};
subtest 'the first generator in a run, pulled from a nursery child' => sub {
    my @collected;
    async {
        my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 7, 14, 21 } );
        nursery(
            sub ($n) {
                $n->spawn(
                    sub {
                        while ( defined( my $v = $gen->next ) ) { push @collected, $v }
                    }
                );
            }
        );
    };
    is "@collected",                            '7 14 21', 'the nursery child pulled every value';
    is Acme::Parataxis::get_live_fiber_count(), 0,         'nothing parked permanently';
};
subtest 'a generator built on the mainline still reserves fid 0' => sub {

    # The mainline is the one place that does still need the reserved fiber: nothing else has allocated a
    # fiber yet, so without it this generator would be fid 0 and hit the Windows resume-die escape.
    my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 1 .. 2 } );
    ok $gen->fiber->fid >= 1, "the generator's fiber is not fid 0 (fid " . $gen->fiber->fid . ')';
    is Acme::Parataxis::get_live_fiber_count(), 1, 'the reserved fiber now exists and is parked';
    is $gen->next,                              1, 'and the generator still works';
};
subtest 'a run after the mainline reserved fiber is clean' => sub {
    my $ran = 0;
    async { $ran = 1 };
    is $ran, 1, 'the run completed';
};
#
done_testing;
