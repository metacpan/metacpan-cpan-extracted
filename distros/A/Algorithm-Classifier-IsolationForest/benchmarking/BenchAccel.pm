package BenchAccel;

# Shared wall-clock timing helpers for the benchmarking/ scripts.
#
# Benchmark::cmpthese is unsafe for comparing OpenMP-parallel code
# against serial code: its rate column is computed from CPU time
# (user + sys), and an OpenMP `parallel for` running on N cores
# consumes ~N x the CPU time of its serial counterpart even when
# wall-clock time drops.  That makes the c_openmp variant look
# *slower* than c_serial in cmpthese output -- the opposite of what
# a user actually experiences.
#
# This module replaces it with three Time::HiRes-based helpers, used
# across every bench script in this directory so they share a single
# timing path:
#
#   wall_cmpthese($target_secs, \%vars)
#       cmpthese-style comparison table, sorted slowest -> fastest with
#       a pairwise percent-difference matrix.  Prints only; returns
#       nothing.  Used when comparing several alternatives at once.
#
#   wall_rate($code, $secs)
#       Warm up briefly, then time $code for $secs wall-clock seconds.
#       Returns ops/second as a scalar.  Used when the script formats
#       its own table (e.g. bench-sklearn-scoring's side-by-side
#       Perl-vs-sklearn rows).
#
#   wall_time_median($code, $reps)
#       Run $code once as a warm-up, then time exactly $reps invocations
#       and return the median elapsed time in seconds.  Used when each
#       invocation is too expensive to run on a time budget (fit() at
#       large sizes); the small fixed sample with median statistic
#       resists outliers without burning a 2-second budget per row.

use strict;
use warnings;
use Time::HiRes qw(time);
use Exporter qw(import);

our @EXPORT_OK = qw(wall_cmpthese wall_rate wall_time_median);

sub wall_cmpthese {
    my ( $target_secs, $vars ) = @_;
    my $target = abs( $target_secs || 0 ) || 1;

    my %res;
    for my $name ( sort keys %$vars ) {
        my $code = $vars->{$name};

        # Warm-up: one call absorbs first-touch and cache-miss spikes
        # so the calibration window measures steady-state cost.
        $code->();

        # Calibrate over 50 ms so the real run lands close to $target s
        # regardless of how fast or slow the variant is.
        my $cal_iters = 0;
        my $cal_t0    = time;
        while ( time - $cal_t0 < 0.05 ) { $code->(); $cal_iters++ }
        my $cal_elapsed = ( time - $cal_t0 ) || 1e-9;
        my $iters
            = int( $cal_iters / $cal_elapsed * $target ) || 1;

        # Real timed run.
        my $t0 = time;
        $code->() for 1 .. $iters;
        my $elapsed = ( time - $t0 ) || 1e-9;
        $res{$name} = { iters => $iters, rate => $iters / $elapsed };
    }

    my @names = sort { $res{$a}{rate} <=> $res{$b}{rate} } keys %res;
    my $name_w = 1;
    for my $n (@names) { $name_w = length $n if length $n > $name_w }
    my $col_w = $name_w < 8 ? 8 : $name_w;

    printf "  %-*s  %10s", $name_w, '', 'Rate';
    printf "  %*s", $col_w, $_ for @names;
    print "\n";

    for my $a (@names) {
        printf "  %-*s  %10s", $name_w, $a, _fmt_rate( $res{$a}{rate} );
        for my $b (@names) {
            if ( $a eq $b ) {
                printf "  %*s", $col_w, '--';
                next;
            }
            my $pct
                = ( $res{$a}{rate} - $res{$b}{rate} )
                / $res{$b}{rate}
                * 100;
            printf "  %*s", $col_w, sprintf( '%+d%%', int($pct) );
        }
        print "\n";
    }
}

sub _fmt_rate {
    my $r = shift;
    return sprintf '%.2g/s', $r if $r < 1;
    return sprintf '%.2f/s', $r if $r < 100;
    return sprintf '%.0f/s',  $r;
}

# wall_rate($code, $secs) -- scalar ops/second over $secs wall-clock
# seconds.  Returns the rate as a plain number so callers can format
# their own tables.
#
# The measurement is split into 3 equal sub-windows and the median of
# their rates is returned.  At small workloads (a few hundred
# microseconds per call) OpenMP thread scheduling is non-deterministic
# enough that a single 2-second window can land in a slow stretch and
# report ~30x lower throughput than steady state; median across
# windows smooths that without spending extra time.
sub wall_rate {
    my ( $code, $secs ) = @_;
    $secs ||= 1;

    # Warm-up: at least 0.3 s (matches the original Perl bench() helper
    # this replaced) so OpenMP thread pools are firmly hot before any
    # measurement window starts.  Scales up for long budgets -- a 30 s
    # measurement gets a 3 s warmup.
    my $warmup = $secs * 0.1;
    $warmup = 0.3 if $warmup < 0.3;
    my $wt0 = time;
    $code->() while time - $wt0 < $warmup;

    my $WINDOWS  = 3;
    my $win_secs = $secs / $WINDOWS;
    my @rates;
    for ( 1 .. $WINDOWS ) {
        my $t0 = time;
        my $n  = 0;
        while ( time - $t0 < $win_secs ) { $code->(); $n++ }
        my $elapsed = ( time - $t0 ) || 1e-9;
        push @rates, $n / $elapsed;
    }
    my @s = sort { $a <=> $b } @rates;
    return $s[ int( @s / 2 ) ];
}

# wall_time_median($code, $reps) -- single warm-up + $reps timed
# invocations; returns the median elapsed time in seconds.  Use this
# when each call is expensive enough that running it on a $secs budget
# would either be wasteful (3 calls in 2 s tells you little more than
# 3 calls in 30 s) or pull in confounders like GC pauses.
sub wall_time_median {
    my ( $code, $reps ) = @_;
    $reps = 5 unless $reps && $reps >= 1;

    $code->();    # warm-up: covers Inline::C compile, first-touch cache

    my @times;
    for ( 1 .. $reps ) {
        my $t0 = time;
        $code->();
        push @times, time - $t0;
    }
    my @s = sort { $a <=> $b } @times;
    return $s[ int( @s / 2 ) ];
}

1;
