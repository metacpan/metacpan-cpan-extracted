use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use blib;
use Time::HiRes     qw[time];
use Acme::Parataxis qw[async fiber yield stop await_sleep maybe_yield];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Signal;
use Acme::Parataxis::Channel;
use Acme::Parataxis::Future;
use Test2::V1 -ipP;
$|++;

BEGIN {
    $SIG{__WARN__} = sub { return if $_[0] =~ qr[^Deep recursion on subroutine]; warn @_ }
}

# Soak test: run the balanced randomized wave from the stress fuzz for at least
# PARATAXIS_STRESS_SECONDS of wall time (default 3s), as many successive waves as
# fit. Every wave ends at a strict boundary (zero fibers, zero outstanding jobs), so
# any resource leak, stack leak, or rare state bug is localised to exactly one wave
# and printed with its seed. Peak live/outstanding counts are tracked to expose slow
# leaks that a single wave could hide. Set PARATAXIS_STRESS_SECONDS high for long
# local runs; CI keeps the default so its soak completes in seconds.
sub newsrng {
    my $seed = @_ ? $_[0] : 1;
    my $s    = $seed;
    return sub {
        $s = ( $s * 1103515245 + 12345 ) & 0x7FFFFFFF;
        return $s;
    };
}
my $BASE_SEED = $ENV{PARATAXIS_STRESS_SEED}    // 0x5EED;
my $SECONDS   = $ENV{PARATAXIS_STRESS_SECONDS} // 3;
my $MAX_WAVES = 5000;
sub live_count  { Acme::Parataxis::get_live_fiber_count() }
sub outstanding { Acme::Parataxis::get_outstanding_jobs() }

sub one_wave ( $seed, $scale ) {
    my $rng  = newsrng($seed);
    my $rand = sub ($n) { $rng->() % $n };
    my %plan = (
        S => $scale * ( 4 + $rand->(16) ),
        G => $scale * ( 1 + $rand->(12) ),
        P => $scale * ( 1 + $rand->(3) ),
        W => $scale * ( 1 + $rand->(10) ),
        A => $rand->(2) ? $scale * ( 4 + $rand->(10) ) : 0
    );
    my $fut  = Acme::Parataxis::Future->new;
    my $sem  = Acme::Parataxis::Semaphore->new( count => 2 );
    my $sig  = Acme::Parataxis::Signal->new;
    my $chan = Acme::Parataxis::Channel->new( capacity => 1 );
    my %inv;
    my @fibers;

    for ( 1 .. $plan{S} ) {
        push @fibers, fiber { await_sleep( 1 + $rand->(5) ) }
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
        push @fibers, fiber { $chan->put( ++$put_seq ) }
    }
    for ( 1 .. $plan{P} ) {
        push @fibers, fiber {
            my $v = $chan->get;
            push @{ $inv{tokens} }, $v;
        };
    }
    for ( 1 .. $plan{W} ) {
        push @fibers, fiber { $sig->wait; $inv{signalled}++ }
    }
    for ( 1 .. $plan{A} ) {
        push @fibers, fiber { my $v = $fut->await; $inv{awaited}++; $inv{fut_value} = $v }
    }
    undef $fibers[$_] for grep { $rand->(5) == 0 } 0 .. $#fibers;
    undef @fibers;
    my $need_ups = $plan{G};
    my $need_sig = $plan{W};
    my ( $ups_done, $fut_set ) = ( 0, 0 );
    for ( 1 .. ( 50 + 20 * $scale + $rand->(40) ) ) {
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

# Prologue: abandon a run mid-flight so a parked fiber and its job are left over; the
# first wave has to reclaim them before it can reach a clean boundary.
async {
    my $leaker = fiber { await_sleep(4) };
    yield for 1 .. 2;
    stop;
};
my $t0 = time;
my ( $waves, $fails ) = ( 0, 0 );
my ( $peak_live, $peak_jobs, $max_scale ) = ( 0, 0, 1 );
my @problems_out;
while ( time - $t0 < $SECONDS && $waves < $MAX_WAVES ) {
    $waves++;
    my $seed  = $BASE_SEED + $waves;
    my $scale = 1 + $waves % 3;
    $max_scale = $scale if $scale > $max_scale;
    my $out;
    eval {
        $out = async { one_wave( $seed, $scale ) }
    };
    if ($@)                   { @problems_out = ( @problems_out, "wave $waves (seed $seed, scale $scale) croak escaped: $@" ); $fails++; last }
    if ( ref $out ne 'HASH' ) { @problems_out = ( @problems_out, "wave $waves (seed $seed) async returned nothing" );          $fails++; last }
    my $plan = $out->{plan};
    my $inv  = $out->{inv};
    my @p;
    push @p, 'fibers left behind (waves must end at a clean boundary)'              if live_count() != 0;
    push @p, 'jobs left outstanding after wave'                                     if outstanding() != 0;
    push @p, "lost semaphore wake: $inv->{guards} guards ran (expected $plan->{G})" if $inv->{guards} != $plan->{G};
    push @p, "lost future wake: $inv->{awaited} awaiters (expected $plan->{A})"     if $plan->{A} && $inv->{awaited} != $plan->{A};
    push @p, "future misdelivered value $inv->{fut_value} (expected v)"             if $plan->{A} && ( $inv->{fut_value} // '' ) ne 'v';
    push @p, "lost signal: $inv->{signalled} waiters woken (expected $plan->{W})"   if $inv->{signalled} != $plan->{W};
    my $tokens = join ',', sort { $a <=> $b } @{ $inv->{tokens} // [] };
    push @p, "channel tokens [$tokens] != 1..$plan->{P}" unless $tokens eq join ',', 1 .. $plan->{P};

    if (@p) {
        $fails++;
        @problems_out = (
            @problems_out,
            'wave ' .
                $waves .
                " (seed $seed; scale $scale; " .
                join( ' ', map {"$_=$plan->{$_}"} sort keys %{ $plan // {} } ) .
                "):\n  " .
                join "\n  ",
            @p
        );
        last;
    }
    $peak_live = live_count()  if live_count() > $peak_live;
    $peak_jobs = outstanding() if outstanding() > $peak_jobs;
}
my $elapsed = sprintf '%.1fs', time - $t0;
ok $fails == 0, "soak: $waves waves in $elapsed (peak scale $max_scale)";
note 'peak live fibers: ' . $peak_live . " (limit ~" . 1024 . ')' if $peak_live;
note 'peak outstanding jobs: ' . $peak_jobs                       if $peak_jobs;
note join "\n", @problems_out if @problems_out;
#
done_testing;
