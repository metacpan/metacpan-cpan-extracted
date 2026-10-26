use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield];
use Acme::Parataxis::Generator;
use Test2::V1 -ipP;
$|++;

# Stackful lazy generator. `Generator->new( code => ... )` runs the code in a private fiber that
# never enters the scheduler run queue; each ->next resumes it with coro_call (asymmetric,
# fully synchronous code only), and exhaustion/error finish the fiber through the normal
# scheduler teardown. A rare Windows quirk makes resume-dies in the very first fiber a
# process escape (see Generator.pm), so the module keeps a parked reserved fiber and real
# generators always land on a non-first slot -- `get_live_fiber_count()` starts at 1 once any
# generator exists.
sub collect ($gen) {
    my @out;
    while ( defined( my $v = $gen->next ) ) { push @out, $v }
    return @out;
}
subtest 'lazy pull: no work happens before the first next' => sub {
    my $started = 0;
    my $gen     = Acme::Parataxis::Generator->new(
        code => sub ($y) {
            $started++;
            $y->($_) for 1, 2, 3;
        }
    );
    ok !$started,      'body has not started yet';
    ok !$gen->is_done, 'not done before the first next';
    is $gen->next, 1, 'first value';
    is $started,   1, 'body only starts on the first next';
    is $gen->next, 2, 'second value';
    is $gen->next, 3, 'third value';
};
subtest 'exhaustion: next returns undef and stays undef, is_done flips' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    my $gen  = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 1, 2, 3 } );
    is $gen->next, 1, 'first';
    is $gen->next, 2, 'second';
    is $gen->next, 3, 'third';
    ok !defined( $gen->next ), 'next after exhaustion is undef';
    ok !defined( $gen->next ), 'repeated next stays undef';
    ok $gen->is_done,          'is_done after exhaustion';
    is Acme::Parataxis::get_live_fiber_count(), $base, 'the exhausted fiber was reaped';
};
subtest 'a body error is rethrown at the next call, then the generator is done' => sub {
    my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->(42); die 'boom from generator' } );
    is $gen->next, 42, 'values before the failure still deliver';
    my $err = dies { $gen->next };
    ok $err, 'the failure throws at the caller';
    like "$err", qr/boom from generator/, 'the original message is rethrown';
    ok $gen->is_done,          'the generator is done after the failure';
    ok !defined( $gen->next ), 'later next calls are undef';
};
subtest 'an error before the first yield also surfaces at the caller' => sub {
    my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { die 'early boom' } );
    my $err = dies { $gen->next };
    ok $err, 'throws on the first next';
    like "$err", qr/early boom/, 'message preserved';
};
subtest 'yields from nested subroutines (deep call stack inside the fiber)' => sub {
    my $gen = Acme::Parataxis::Generator->new(
        code => sub ($y) {
            for my $i ( 1 .. 5 ) {
                sub {
                    sub { $y->( $i * 10 ) }
                        ->();
                    }
                    ->();
            }
        }
    );
    my @vals = collect($gen);
    ok "@vals" eq '10 20 30 40 50', 'every deep-nested value arrives in order';
};
subtest 'consumption inside an async (scheduled) block' => sub {
    my @collected;
    async {
        my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 7, 14, 21 } );
        ok !$gen->is_done, 'not done while mid-collection';
        @collected = collect($gen);
    };
    ok "@collected" eq '7 14 21', 'all values collected from within a scheduled fiber';
};
subtest 'consumption from a spawned (non-main) fiber' => sub {
    my @collected;
    my $done = 0;
    async {
        my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 'a' .. 'c' } );
        fiber {
            @collected = collect($gen);
            $done      = 1;
        };
        yield until $done;
    };
    ok "@collected" eq 'a b c', 'the generator was pulled from a child fiber';
};
subtest 'destroying an unexhausted generator drains its fiber cleanly' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    my $gen;
    {
        my $kept = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 1 .. 10 } );
        $kept->next;
        $kept->next;
        $gen = $kept;
    }
    is Acme::Parataxis::get_live_fiber_count(), $base + 1, 'unexhausted generator keeps a live fiber';
    undef $gen;
    is Acme::Parataxis::get_live_fiber_count(), $base, 'DESTROY released the suspended fiber';
};
subtest 'abandoning an infinite generator frees it at scope exit' => sub {
    my $gc = Acme::Parataxis::get_live_fiber_count();
    {
        my $gen = Acme::Parataxis::Generator->new(
            code => sub ($y) {
                while (1) { $y->(1) }
            }
        );
        $gen->next;
    }
    is Acme::Parataxis::get_live_fiber_count(), $gc, 'the infinite generator was drained at scope exit';
};
subtest 'the private fiber is reusable across exhaustion and a later generator' => sub {
    my $gen = Acme::Parataxis::Generator->new( code => sub ($y) { $y->($_) for 1 .. 2 } );
    is $gen->next, 1, 'g1 first';
    my @rest;
    while ( defined( my $x = $gen->next ) ) { push @rest, $x }
    is "@rest", '2', 'the remaining value still comes out';
    my $gen2 = Acme::Parataxis::Generator->new( code => sub ($y) { $y->(9) } );
    is $gen2->next, 9, 'a fresh generator creates a fresh fiber';
    ok !defined( $gen2->next ), 'and exhausts normally';
};
subtest 'a body that dies with the old sentinel string still surfaces (no silent drain swallow)' => sub {
    my $gen = Acme::Parataxis::Generator->new(
        code => sub ($y) {
            $y->('ok');
            die '__PARATAXIS_GENERATOR_DRAIN__';
        }
    );
    is $gen->next, 'ok', 'the first value delivers';
    my $err = dies { $gen->next };
    ok $err, 'the die surfaces instead of being mistaken for a drain';
    like "$err", qr/__PARATAXIS_GENERATOR_DRAIN__/, 'the exact message is preserved';
    ok $gen->is_done, 'the generator is done after the failure';
};
subtest 'yielding the sentinel lookalike string is ordinary data' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    {
        my $kept = Acme::Parataxis::Generator->new(
            code => sub ($y) {
                $y->('__PARATAXIS_GENERATOR_DRAIN__');
                $y->('tail');
            }
        );
        is $kept->next, '__PARATAXIS_GENERATOR_DRAIN__', 'the lookalike yields as a plain value';
    }
    is Acme::Parataxis::get_live_fiber_count(), $base, 'DESTROY drained the suspended generator cleanly';
};
#
done_testing;
