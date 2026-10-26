use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';
use Acme::Parataxis;

# Stackful lazy iterator backed by a private coroutine.
class Acme::Parataxis::Generator v0.1.1 {
    use Carp qw[croak];
    our $RESERVED;
    our $DRAIN = \do { my $x = 1 };    # an opaque scalar ref, so no user yield/die value can collide with the marker
    field $code : param;               # the user's producer; kept so construction can validate and seed the driver
    field $fiber;                      # the private fiber the body runs on
    field $err_ref;                    # ref to the fiber-local error the driver parks the body's die in

    # The body's yield: suspends the private fiber and returns the next value to ->next. When DESTROY resumes
    # the fiber to drain it, coro_yield returns our drain marker and the closure dies with it so the body stops
    # on the next suspension boundary. The fiber never enters the scheduler run queue; each ->next resumes it via
    # coro_call, i.e. it parks in the same way a coroutine parks, and exhaustion/error finish the fiber normally.
    # Windows longjmp across the very first fiber allocated in a process (fid 0) is unreliable (the body's die
    # escapes every anchored JMPENV -> "uncaught die" or 0xC0000005), so a generator must never land on fid 0; see
    # _ensure_reserved_fiber below. A die raised by the body on a resumed trip is caught here (the scheduler's own
    # G_EVAL can miss it on resume, see the fid-0 note) and the error string is parked in $err_ref, which ->next
    # dereferences and rethrows on the caller's stack, so no die ever crosses a transfer.
    ADJUST {
        croak 'Generator->new() requires a CODE ref' unless ref $code eq 'CODE';
        _ensure_reserved_fiber();
        my $yield = sub ($value) {
            my $got = Acme::Parataxis::coro_yield( [$value] );
            die $got->[0] if ref $got eq 'ARRAY' && @$got == 1 && ref( $got->[0] ) eq 'SCALAR' && $got->[0] == $DRAIN;
            return;
        };
        my $err;
        my $driver = sub {
            try { $code->($yield) } catch ($caught) {
                $err = $caught
            }
            return;
        };
        $fiber   = Acme::Parataxis->new( code => $driver );
        $err_ref = \$err;
    }

    method next () {
        return undef if $fiber->is_done;
        my $rv = Acme::Parataxis::coro_call( $fiber->fid, [] );
        return ( ref $rv eq 'ARRAY' ) ? $rv->[0] : undef unless $fiber->is_done;
        my $err = ${$err_ref};
        die $err if defined $err && !( ref($err) eq 'SCALAR' && $err == $DRAIN );
        return undef;
    }
    method is_done () { $fiber->is_done }
    method fiber ()   {$fiber}              # the private fiber (fid inspection, tests)

    # An unexhausted (suspended) fiber is drained to its natural exit instead of being torn down in mid-shot:
    # resuming it with the drain marker makes the yield closure die, the fiber-local try/catch absorbs it, and the
    # fiber finishes normally (perl unwinds its own scopes), after which coro_call reaps it. (destroy_coro
    # mid-eval became safe with the C-level fix that made destroying a parked fiber safe, but draining is retained
    # so the body can run its own finalization.)
    method DESTROY () {
        return if !defined $fiber;
        my $fid = $fiber->fid;
        return if !defined $fid || $fid < 0;
        if ( !$fiber->is_done ) {

            # try/catch neither reads nor writes $@, so the local $@ this used to need (to keep a
            # failed drain from clobbering the caller's error) is gone along with the eval.
            try { Acme::Parataxis::coro_call( $fid, [$DRAIN] ) } catch ($caught) {
            }
        }
        return if $fiber->is_done;
        Acme::Parataxis::destroy_coro($fid);
        $fiber->[Acme::Parataxis::F_FID]     = -1;
        $fiber->[Acme::Parataxis::F_IS_DONE] = 1;
        return;
    }

    # The reserved fiber is a permanent gift of fid 0, so every generator lands on fid >= 1. On the mainline
    # nothing else has allocated a fiber yet, so one permanently parked fiber takes fid 0. Inside a run the run's
    # own main fiber already holds fid 0 before the body executes, so a generator built there is on fid >= 1
    # regardless and reserving again buys nothing: all it adds is a fiber parked for the lifetime of the process,
    # which the scheduler's deadlock detector counts as run work and trips over when that run ends.
    # (Acme::Parataxis snapshots %PRESET_FIBERS when a run starts, so a fiber born *during* the run is not
    # excluded from that count the way a fiber from an earlier run is.)
    sub _ensure_reserved_fiber {
        return if $RESERVED;
        return if Acme::Parataxis->current_fid >= 0;    # a run already owns fid 0; do not add a permanent fiber
        my $fiber = Acme::Parataxis->new(
            code => sub {
                Acme::Parataxis::coro_yield( [] );
                return;
            }
        );
        Acme::Parataxis::coro_call( $fiber->fid, [] );
        $RESERVED = $fiber;
        return;
    }
};
#
1;
