use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use blib;
use Acme::Parataxis qw[async fiber yield stop await_sleep maybe_yield];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Signal;
use Acme::Parataxis::Channel;
use Acme::Parataxis::Future;
use Test2::V1 -ipP;
$|++;

# Fibers run on separate heap stacks; Perl's C-stack-depth heuristic can misfire and falsely report "Deep recursion"
# (it ignores lexical 'no warnings' once a framework such as Test2 is loaded). Genuine runaway recursion inside a fiber
# surfaces as a hang, access violation, or croak the harness already catches, so filter the noise.
BEGIN {
    $SIG{__WARN__} = sub { return if $_[0] =~ /^Deep recursion on subroutine/; warn @_ }
}

# Seeded randomized concurrency harness ("interleaving fuzzer").
#
# Each iteration builds a fresh, *balanced* ecosystem of fibers (sleepers, semaphore guards, channel
# producers/consumers, signal waiters, future awaiters) and the main fiber then interleaves operations in a
# seeded-random order. The population is balanced so every parked fiber is guaranteed to be woken and a run must
# terminate on its own; any fiber left behind, any croak, lost/double delivery, or count drift fails the iteration. Set
# PARATAXIS_STRESS_SEED / PARATAXIS_STRESS_ITER to repeat or zoom. The seed is reported per-failure so bugs reproduce
# exactly.
sub newsrng {
    my $seed = @_ ? $_[0] : 1;
    my $s    = $seed;
    return sub {
        $s = ( $s * 1103515245 + 12345 ) & 0x7FFFFFFF;
        return $s;
    };
}
my $BASE_SEED = $ENV{PARATAXIS_STRESS_SEED} // 0xC0FFEE;
my $ITERS     = $ENV{PARATAXIS_STRESS_ITER} // 8;
sub live_count  { Acme::Parataxis::get_live_fiber_count() }
sub outstanding { Acme::Parataxis::get_outstanding_jobs() }

sub one_iteration ($seed) {
    my $rng  = newsrng($seed);
    my $rand = sub ($n) { $rng->() % $n };

    # Random, but *balanced*, population: every fiber is guaranteed to be woken by the planned ops below. Randomness
    # breaks up interleavings, never the totals.
    my %plan = (
        S => 4 + $rand->(16),                     # sleepers (never need waking)
        G => 1 + $rand->(12),                     # semaphore guards (woken by the planned ups)
        P => 1 + $rand->(3),                      # channel producer/consumer pairs (rendezvous)
        W => 1 + $rand->(10),                     # signal waiters (woken by the planned sends)
        A => $rand->(2) ? 4 + $rand->(10) : 0,    # future awaiters
    );
    my $fut  = Acme::Parataxis::Future->new;
    my $sem  = Acme::Parataxis::Semaphore->new( count => 2 );
    my $sig  = Acme::Parataxis::Signal->new;
    my $chan = Acme::Parataxis::Channel->new( capacity => 1 );
    my %inv;
    my @fibers;
    for ( 1 .. $plan{S} ) {
        push @fibers, fiber { await_sleep( 1 + $rand->(5) ) };
    }
    for ( 1 .. $plan{G} ) {
        push @fibers, fiber {
            my $g = $sem->guard;
            yield for 1 .. 2;
            undef $g;
            $inv{guards}++;
        };
    }
    my $put_seq = 0;
    for ( 1 .. $plan{P} ) {
        push @fibers, fiber { $chan->put( ++$put_seq ) };
    }
    for ( 1 .. $plan{P} ) {
        push @fibers, fiber {
            my $v = $chan->get;
            push @{ $inv{tokens} }, $v;
        };
    }
    for ( 1 .. $plan{W} ) {
        push @fibers, fiber { $sig->wait; $inv{signalled}++ };
    }
    for ( 1 .. $plan{A} ) {
        push @fibers, fiber { my $v = $fut->await; $inv{awaited}++; $inv{fut_value} = $v };
    }

    # Drop the Perl reference to a random subset while they are still parked: the C
    # context keeps them alive, but this exercises destroy-without-a-Perl-reference.
    undef $fibers[$_] for grep { $rand->(5) == 0 } 0 .. $#fibers;
    undef @fibers;

    # Interleave random operations, sprinkling in the balanced sends and guaranteeing
    # every planned send actually happens.
    my $need_ups = $plan{G};
    my $need_sig = $plan{W};
    my ( $ups_done, $fut_set ) = ( 0, 0 );
    for ( 1 .. 20 + $rand->(40) ) {
        my $op = $rand->(8);
        if    ( $op == 0 && $need_ups )             { $sem->up;   $need_ups-- }
        elsif ( $op == 1 && $need_sig )             { $sig->send; $need_sig-- }
        elsif ( $op == 2 )                          { $sem->up }
        elsif ( $op == 3 )                          { $sig->send }
        elsif ( $op == 4 && !$fut_set && $plan{A} ) { $fut->set_result('v'); $fut_set = 1 }
        elsif ( $op == 5 )                          { await_sleep(1) }
        elsif ( $op == 6 )                          {yield}
        else                                        {maybe_yield}
    }
    $sem->up   for 1 .. $need_ups;
    $sig->send for 1 .. $need_sig;
    $fut->set_result('v') if $plan{A} && !$fut_set;
    maybe_yield for 1 .. 3;
    return { plan => \%plan, inv => \%inv };
}

# Prologue: abort a run mid-flight so a parked fiber and its job are left over; every subsequent iteration has to drain
# and reclaim that leftover while running its own population. This is the cross-run contamination case from the
# hardening pass.
async {
    my $leaker = fiber { await_sleep(4) };
    yield for 1 .. 2;
    stop;
};
my ( $pass, $fails ) = ( 0, 0 );
my @problems_out;
for my $iter ( 1 .. $ITERS ) {
    my $seed = $BASE_SEED + $iter;
    my ( $out, $err );
    eval {
        $out = async { one_iteration($seed) }
    };
    if ($@)                   { @problems_out = ( @problems_out, "iter $iter (seed $seed) croak escaped: $@" );      next }
    if ( ref $out ne 'HASH' ) { @problems_out = ( @problems_out, "iter $iter (seed $seed) async returned nothing" ); next }
    my $plan = $out->{plan};
    my $inv  = $out->{inv};
    my @p;
    push @p, 'fibers left behind (a clean run must exit with zero)'                 if live_count() != 0;
    push @p, 'jobs left outstanding after run'                                      if outstanding() != 0;
    push @p, "lost semaphore wake: $inv->{guards} guards ran (expected $plan->{G})" if $inv->{guards} != $plan->{G};
    push @p, "lost future wake: $inv->{awaited} awaiters (expected $plan->{A})"     if $plan->{A} && $inv->{awaited} != $plan->{A};
    push @p, "future misdelivered value $inv->{fut_value} (expected v)"             if $plan->{A} && ( $inv->{fut_value} // '' ) ne 'v';
    push @p, "lost signal: $inv->{signalled} waiters woken (expected $plan->{W})"   if $inv->{signalled} != $plan->{W};
    my $tokens = join ',', sort { $a <=> $b } @{ $inv->{tokens} // [] };
    push @p, "channel tokens [$tokens] != 1..$plan->{P}" if $tokens ne join( ',', 1 .. $plan->{P} );

    if (@p) {
        $fails++;
        @problems_out = (
            @problems_out,
            'iter ' . $iter . " (seed $seed; " . join( ' ', map {"$_=$plan->{$_}"} sort keys %{ $plan // {} } ) . "):\n  " . join "\n  ", @p
        );
    }
    else {
        $pass++;
    }
}
ok $fails == 0, "stress fuzz: $pass/$ITERS clean iterations";
note join "\n", @problems_out if @problems_out;
#
done_testing;
