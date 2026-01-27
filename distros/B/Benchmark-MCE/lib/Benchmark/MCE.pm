package Benchmark::MCE;

use strict;
use warnings;

use Config;
use Exporter 'import';
use List::Util qw(min max sum);
use Time::HiRes qw(CLOCK_MONOTONIC);

use MCE::Loop;
use System::CPU;
use System::Info;

our $VERSION    = '1.02';
our @EXPORT     = qw(system_identity suite_run calc_scalability suite_calc);
our $MONO_CLOCK = $^O !~ /win/i || $Time::HiRes::VERSION >= 1.9764;
our $QUIET      = 0;

=head1 NAME

Benchmark::MCE - Perl multi-core benchmarking framework

=head1 SYNOPSIS

  use Benchmark::MCE;

  # Run 2 benchmarks (custom functions) and time them on a single core:
  my %stat_single = suite_run({
    threads => 1,
    bench   => {
      Bench1 => sub { ...code1... },
      Bench2 => '...code2...'       # String is also fine
    }
  );

  # Run each across multiple cores.
  # Use the extended (arrayref) definition to check for correctness of output.
  my %stat_multi = suite_run({
    threads => system_identity(1),  # Workers count equal to system logical cores
    bench   => {
      Bench1 => [\&code1, $expected_output1],
      Bench2 => [\&code2, $expected_output2],
    }
  );
  
  # Calculate the multi/single core scalability
  my %scal = calc_scalability(\%stat_single, \%stat_multi);

=head1 DESCRIPTION

A benchmarking framework originally designed for the L<Benchmark::DKbench> multi-core
CPU benchmarking suite. Released as a stand-alone to be used for custom benchmarks
of any type, as well as other kinds of stress-testing, throughput testing etc. 

You define custom functions (usually with randomized workloads) that can be run on
any number of parallel workers, using the low-overhead Many-Core Engine (L<MCE>).

=head1 FUNCTIONS
 
=head2 C<system_identity>

 my $cores = system_identity($quiet?);

Prints out software/hardware configuration and returns the number of logical cores
detected using L<System::CPU>.

Any argument will suppress printout and will only return the number of cores.

=head2 C<suite_run>

 my %stats = suite_run(\%options);

Runs the benchmark suite given the C<%options> and prints results. Returns a hash
with run stats that looks like this:

 %stats = (
   $bench_name_1 => {times => [ ... ], scores => [ ... ]},
    ...
   _total => {times => [ ... ], scores => [ ... ]},
   _opt   => {iter => $iterations, threads => $no_threads, ...}
 );

Note that the times reported will be average times per thread (or per function
call if you prefer), however the scores reported (if a reference time is supplied)
are sums across all threads. So you expect for ideal scaling 1 thread vs 2 threads
to return the same times, double the scores.

=head3 Options:

=over 4

=item * C<bench> (HashRef) B<required>:
A hashref with keys being your unique custom benchmark names and values being
arrays:

C<< name => [ $coderef, $expected?, $ref_time?, $quick_arg?, $normal_arg? ] >>

where:

=over 4

=item * C<$coderef> B<required>:
Reference to your benchmark function. See L<BENCHMARK FUNCTIONS> for more details.

=item * C<$expected>:
Expected output of the benchmark function on successful run (for PASS/FAIL - PASS
will be always assumed is parameter is undefined).

=item * C<$ref_time>:
Reference time in seconds for score of 1000.

=item * C<$quick_arg>:
Argument to pass to the benchmark function in C<quick> mode (for workload scaling).

=item * C<$normal_arg>:
Argument to pass to the benchmark function in normal mode (for workload scaling).

=back

=item * C<threads> (Int; default 1):
Parallel benchmark threads. They are L<MCE> workers, so not 'threads' in the technical
sense. Each of the benchmarks defined will launch on each of the threads, hence the
total workload is multiplied by the number of C<threads>. Times will be averaged
across threads, while scores will be summed.

=item * C<iter> (Int; default 1):
Number of suite iterations (with min/max/avg at the end when > 1).

=item * C<include> (Regex):
Only run benchmarks whose names match regex.

=item * C<exclude> (Regex):
Skip benchmarks whose names match regex.

=item * C<time> (Bool):
Report time (sec) instead of score. Set to true by C<quick> or if at least one
benchmark has no reference time declared. Otherwise score output is the default.

=item * C<quick> (Bool; default 0):
Use each benchmark's quick argument and imply C<time=1>.

=item * C<scale> (Int; default 1):
Scale the bench workload (number of calls of the benchmark functions) by x times.
Forced to 1 with C<quick> or C<no_mce>.

=item * C<stdev> (Bool; default 0):
Show relative standard deviation (for C<iter> > 1).

=item * C<sleep> (Int; default 0):
Number of seconds to sleep after each benchmark run.

=item * C<duration> (Int, seconds):
Minimum duration in seconds for suite run (overrides C<iter>).

=item * C<srand> (Int; default 1):
Define a fixed seed to keep runs reproducible when your benchmark functions use
C<rand>. The seed will be passed to C<srand> before each call to a benchmark
function. Set to 0 to skip rand seeding.

=item * C<no_check> (Bool; default 0):
Do not check for Pass/Fail even if reference output is defined.

=item * C<no_mce> (Bool; default 0):
Do not run under L<MCE::Loop> (sets C<threads=1>, C<scale=1>).

=back

=head2 C<calc_scalability>

 my %scal = calc_scalability(\%stat_single, \%stat_multi, $keep_outliers?);

Given the C<%stat_single> results of a single-threaded C<suite_run> and C<%stat_multi>
results of a multi-threaded run, will calculate, print and return the multi-thread
scalability (including averages, ranges etc for multiple iterations).

Unless C<$keep_outliers> is true, the overall scalability is an average after droping
Benchmarks that are non-scaling outliers (over 2*stdev less than the mean).

The result hash return looks like this:

 %scal = (
   bench_name => $bench_avg_scalability,
    ...
   _total => $total_avg_scalability
 );


=head2 C<suite_calc>

 my ($stats, $stats_multi, $scal) = suite_calc(\%suite_run_options, $keep_outliers?);

Convenience function that combines 3 calls, L</suite_run> with C<threads=E<gt>1>,
L</suite_run> with C<threads=E<gt>system_identity(1)> and L</calc_scalability> with
the results of those two, returning hashrefs with the results of all three calls.

For single-core systems (or when C<system_identity(1)> does not return E<gt> 1)
only C<$stats> will be returned.

You can override the C<system_identity(1)> call and run the multi-thread bench with
a custom number of threads by passing C<threads =E<gt> [count]>.

=head1 BENCHMARK FUNCTIONS

The benchmark functions will be called with two parameters that you can choose to
take advantage of.
The first one is what you define as either the C<$quick_arg> or C<$normal_arg>,
with the intention being to have a way to run a C<quick> mode that lets you test with
smaller workloads. The second argument will be an integer that's the chunk number
from L<MCE::Loop> - it will be 1 for the call on the first thread, 2 from the second
thread etc, so your function may track which worker/chunk is running.

The function may return a string, usually a checksum, that will be checked against
the (optional) C<$expected> parameter to show a Pass/Fail (useful for verifying
correctness, stress testing, etc.).

Example:

  use Benchmark::MCE;
  use Math::Trig qw/:great_circle :pi/;

  sub great_circle {
    my $size  = shift || 1;  # Optionally have an argument that scales the workload
    my $chunk = shift;       # Optionally use the chunk number
    my $dist = 0;
    $dist +=
      great_circle_distance(rand(pi), rand(2 * pi), rand(pi), rand(2 * pi))
        for 1 .. $size;
    return $dist; # Returning a value is optional for the Pass/Fail functionality
  }

  my %stats = suite_run({
      bench => { 'Math::Trig' =>  # A unique name for the benchmark
        [
        \&great_circle,      # Reference to bench function
        '3144042.81433949',  # Reference output - determines Pass/Fail (optional)
        5.5,                 # Seconds to complete in normal mode for score = 1000 (optional)
        1000000,             # Argument to pass for quick mode (optional)
        5000000              # Argument to pass for normal mode (optional)
        ]},
    }
  );

=head1 STDOUT / QUIET MODE

Normally function calls will print results to C<STDOUT> as well as return them.
You can suppress STDOUT by setting:

  $Benchmark::MCE::QUIET = 1;

=head1 NOTES

The framework uses a monotonic timer for non-Windows systems with at least v1.9764
of C<Time::HiRes> (C<$Benchmark::MCE::MONO_CLOCK> will be true).

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on L<GitHub|https://github.com/SpareRoom/Benchmark-MCE>.

=head1 GIT

L<https://github.com/SpareRoom/Benchmark-MCE>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2021-2025 Dimitrios Kechagias.
Copyright (c) 2025 SpareRoom.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

sub system_identity {
    my ($physical, $cores, $ncpu) = System::CPU::get_cpu;
    $ncpu ||= 1;
    return $ncpu if @_;

    local $^O = 'linux' if $^O =~ /android/;
    my $info  = System::Info->sysinfo_hash;
    my $osn   = $info->{distro} || $info->{os} || $^O;
    my $model = System::CPU::get_name || '';
    my $arch  = System::CPU::get_arch || '';
    $arch = " ($arch)" if $arch;
    _print("--------------- Software ---------------\n",_package_ver(),"\n");
    _printf(
        "Perl $^V (%sthreads, %smulti)\n",
        $Config{usethreads}      ? '' : 'no ',
        $Config{usemultiplicity} ? '' : 'no '
    );
    _print("OS: $osn\n--------------- Hardware ---------------\n");
    _print("CPU type: $model$arch\n");
    _print("CPUs: $ncpu");
    my @extra;
    push @extra, "$physical Processors" if $physical && $physical > 1;
    push @extra, "$cores Cores" if $cores;
    push @extra, "$ncpu Threads" if $cores && $cores != $ncpu;
    _print(" (".join(', ', @extra).")") if @extra;
    _print("\n".("-"x40)."\n");

    return $ncpu;
};

sub suite_calc {
    my $opt      = shift;
    my $outliers = shift;
    my %single   = suite_run({%$opt, threads => 1});
    my $cpus     = $opt->{threads} || system_identity(1);
    return \%single unless $cpus > 1;
    my %multi = suite_run({%$opt, threads => $cpus});
    return \%single, \%multi, {calc_scalability(\%single, \%multi, $outliers)};
}

sub suite_run {
    my $opt = shift;
    _init_options($opt);

    my %stats;
    $stats{_opt}->{$_} = $opt->{$_} foreach qw/threads scale iter time no_check/;

    my $thread = $opt->{threads} > 1 ? "$opt->{threads}-thread" : "single-thread";
    _print(__PACKAGE__, " $thread run");
    _print($opt->{no_mce} ? " (no MCE):\n" : ":\n");

    MCE::Loop::init {
        max_workers => $opt->{threads},
        chunk_size  => 1,
    } unless $opt->{no_mce};

    if ($opt->{duration}) {
        my $t0  = _get_time();
        my $cnt = 0;
        my $t   = 0;
        while ($t < $opt->{duration}) {
            $cnt++;
            _print("Iteration $cnt (".int($t+0.5)."s of $opt->{duration}s)...\n");
            _run_iteration($opt, \%stats);
            $t = _get_time()-$t0;
        }
        $opt->{iter}         = $cnt;
        $stats{_opt}->{iter} = $cnt;
        $opt->{duration}     = 0;
    } else {
        foreach (1..$opt->{iter}) {
            _print("Iteration $_ of $opt->{iter}...\n") if $opt->{iter} > 1;
            _run_iteration($opt, \%stats);
        }
    }

    _total_stats($opt, \%stats) if $opt->{iter} > 1;

    return %stats;
}

sub calc_scalability {
    my $stats1   = shift;
    my $stats2   = shift;
    my $outliers = shift;
    my $opt      = $stats1->{_opt};
    my $opt2     = $stats2->{_opt};

    die "Different, non-zero thread count expected between runs"
        if !$opt->{threads}
        || !$opt2->{threads}
        || $opt->{threads} == $opt2->{threads};

    ($opt, $opt2) = ($stats2->{_opt}, $stats1->{_opt})
        if $opt->{threads} > $opt2->{threads};

    die "Same scale expected between runs" if $opt->{scale} != $opt2->{scale};

    my $threads = $opt2->{threads} / $opt->{threads};
    my $display = $opt->{time} ? 'times' : 'scores';

    $opt->{f} = $opt->{time} ? '%.3f' : '%5.0f';
    my ($cnt, @perf, @scal, %scal);
    _print(   "Multi thread Scalability:\n"
            . _pad("Benchmark",           24)
            . _pad("Multi perf xSingle",  24)
            . _pad("Multi scalability %", 24)
            . "\n");
    foreach my $bench (sort keys %{$stats1}) {
        next if $bench eq '_total';
        next unless $stats1->{$bench}->{times} && $stats2->{$bench}->{times};
        $cnt++;
        my @res1 = _min_max_avg($stats1->{$bench}->{times});
        my @res2 = _min_max_avg($stats2->{$bench}->{times});
        $scal{$bench} = $res1[2]/$res2[2]*100 if $res2[2];
        push @perf, $res1[2]/$res2[2]*$threads if $res2[2];
        push @scal, $scal{$bench} if $scal{$bench};
        _print(   _pad("$bench:", 24)
                . _pad(sprintf("%.2f",  $perf[-1]), 24)
                . _pad(sprintf("%2.0f", $scal[-1]), 24) . "\n")
            if @perf;
    }
    die "No bench times recorded" unless @perf;
    _print(("-"x40)."\n");
    my @avg1 = _min_max_avg($stats1->{_total}->{$display});
    my @avg2 = _min_max_avg($stats2->{_total}->{$display});
    _print(__PACKAGE__, " summary ($cnt benchmark");
    _print("s") if $cnt > 1;
    _print(" x$opt->{scale} scale")     if $opt->{scale} > 1;
    _print(", $opt->{iter} iterations") if $opt->{iter} > 1;
    _print(", $opt2->{threads} threads):\n");
    $opt->{f} .= "s" if $opt->{time};
    my $f = $opt->{time} ? '%.3f' : '%.0f';
    $f = $opt->{iter} > 1 ? "$opt->{f}\t($f - $f)" : $opt->{f};
    @avg1 =  $opt->{iter} > 1 ? ($avg1[2], $avg1[0], $avg1[1]) : ($avg1[2]);
    @avg2 =  $opt->{iter} > 1 ? ($avg2[2], $avg2[0], $avg2[1]) : ($avg2[2]);
    _print(_pad("Single:").sprintf($f, @avg1)."\n");
    _print(_pad("Multi:").sprintf($f, @avg2)."\n");
    my @newperf = $outliers ? @perf : _drop_outliers(\@perf, -1);
    my @newscal = $outliers ? @scal : _drop_outliers(\@scal, -1);
    @perf = _min_max_avg(\@newperf);
    @scal = _min_max_avg(\@newscal);
    $scal{_total} = $scal[2];
    _print(   _pad("Multi/Single perf:")
            . sprintf("%.2fx\t(%.2f - %.2f)", $perf[2], $perf[0], $perf[1])
            . "\n");
    _print(
        _pad("Multi scalability:") . sprintf(
            "%2.1f%% \t(%.0f%% - %.0f%%)", $scal[2], $scal[0], $scal[1]
            )
            . "\n"
    );

    return %scal;
}

sub _init_options {
    my $opt = shift;
    $opt->{iter}  ||= $opt->{iterations} || 1;
    $opt->{bench} ||= $opt->{benchmarks} || $opt->{extra_bench};
    die "No benchmarks defined" unless $opt->{bench} && %{$opt->{bench}};
    foreach my $b (keys %{$opt->{bench}}) {
        if (!ref($opt->{bench}->{$b})) { # string
            my $f = eval "sub { $opt->{bench}->{$b} }";
            die "Error compiling benchmark '$b': $@" if $@;
            $opt->{bench}->{$b} = $f;
        }
        $opt->{bench}->{$b} = [$opt->{bench}->{$b}]
            if ref($opt->{bench}->{$b}) eq 'CODE';    # wrap coderef
        die "Error defining benchmark '$b'"
            if ref($opt->{bench}->{$b}) ne 'ARRAY';
    }
    $opt->{threads} ||= 1;
    $opt->{scale}   ||= 1;
    ($opt->{time}, $opt->{no_check}) = (1, 1) if $opt->{quick};
    $opt->{scale} = 1 if $opt->{quick} || $opt->{no_mce};
    foreach my $arr (values %{$opt->{bench}}) {
        $opt->{time}     = 1 unless scalar(@$arr) > 2 && $arr->[2] && $arr->[2] > 0;
        $opt->{no_check} = 1 unless scalar(@$arr) > 1 && defined $arr->[1];
    }
    $opt->{f} = $opt->{time} ? '%.3f' : '%5.0f';
    $opt->{threads} = 1 if $opt->{no_mce};
}

sub _run_iteration {
    my $opt        = shift;
    my $stats      = shift;
    my $benchmarks = $opt->{bench};
    my $title      = $opt->{time} ? 'Time (sec)' : 'Score';
    _print(_pad("Benchmark")._pad($title));
    _print("Pass/Fail") unless $opt->{no_check};
    _print("\n");
    my ($total_score, $total_time, $i) = (0, 0, 0);
    foreach my $bench (sort keys %$benchmarks) {
        next if $opt->{filter} && !$opt->{filter}->($opt, $bench, $benchmarks->{$bench});
        next if $opt->{exclude} && $bench =~ /$opt->{exclude}/;
        next if $opt->{include} && $bench !~ /$opt->{include}/;
        my ($time, $res) = _mce_bench_run($opt, $benchmarks->{$bench});
        my $score =
            $benchmarks->{$bench}->[2] && $time
            ? int(1000 * $opt->{threads} * $benchmarks->{$bench}->[2] / $time + 0.5)
            : 1;
        $total_score += $score;
        $total_time  += $time;
        $i++;
        push @{$stats->{$bench}->{times}}, $time;
        push @{$stats->{$bench}->{scores}}, $score;
        my $d = $stats->{$bench}->{$opt->{time} ? 'times' : 'scores'}->[-1];
        $stats->{$bench}->{fail}++ if !$opt->{quick} && $res ne 'Pass';
        _print(_pad("$bench:")._pad(sprintf($opt->{f}, $d)));
        _print("$res") unless $opt->{no_check};
        _print("\n");
        sleep $opt->{sleep} if $opt->{sleep};
    }
    die "No tests to run\n" unless $i;
    my $s = int($total_score/$i+0.5);
    _print(_pad("Overall $title: ")
            . sprintf($opt->{f} . "\n", $opt->{time} ? $total_time : $s));
    push @{$stats->{_total}->{times}}, $total_time;
    push @{$stats->{_total}->{scores}}, $s;
}

sub _mce_bench_run {
    my $opt        = shift;
    my $benchmark  = shift;
    my @bench_copy = @$benchmark;
    $bench_copy[3] = $bench_copy[4] if scalar(@bench_copy) > 3 && !$opt->{quick};
    return _bench_run(\@bench_copy, 1, $opt->{srand}) if $opt->{no_mce};

    my @stats = mce_loop {
        my ($mce, $chunk_ref, $chunk_id) = @_;
        for (@{$chunk_ref}) {
            my ($time, $res) = _bench_run(\@bench_copy, $_, $opt->{srand});
            MCE->gather([$time, $res]);
        }
    }
    (1 .. $opt->{threads} * $opt->{scale});

    my ($res, $time) = ('Pass', 0);
    foreach (@stats) {
        $time += $_->[0];
        $res = $_->[1] if $_->[1] ne 'Pass';
    }

    return $time/$opt->{threads} * $opt->{scale}, $res;
}

sub _bench_run {
    my $benchmark = shift;
    my $chunk_no  = shift;
    my $srand     = shift // 1;
    srand($srand) if $srand > 0; # For repeatability
    my $t0   = _get_time();
    my $out  = $benchmark->[0]->($benchmark->[3], $chunk_no);
    my $time = sprintf("%.3f", _get_time()-$t0);
    my $r    = !defined $benchmark->[1]
        || $out eq $benchmark->[1] ? 'Pass' : "Fail ($out)";
    return $time, $r;
}

sub _total_stats {
    my $opt     = shift;
    my $stats   = shift;
    my $display = $opt->{time} ? 'times'      : 'scores';
    my $title   = $opt->{time} ? 'Time (sec)' : 'Score';
    _print(   "Aggregates ($opt->{iter} iterations"
            . ($opt->{threads} > 1 ? ", $opt->{threads} threads" : "") . "):\n"
            . _pad("Benchmark", 24)
            . _pad("Avg $title")
            . _pad("Min $title")
            . _pad("Max $title"));
    _print(_pad("stdev %")) if $opt->{stdev};
    _print(_pad("Pass %")) unless $opt->{no_check};
    _print("\n");

    foreach my $bench (sort keys %{$opt->{bench}}) {
        next unless $stats->{$bench}->{$display};
        my $str = _calc_stats($opt, $stats->{$bench}->{$display});
        _print(_pad("$bench:",24).$str);
        _print(
            _pad(
                sprintf("%d",
                    100 * ($opt->{iter} - ($stats->{$bench}->{fail} || 0)) /
                        $opt->{iter})
            )
        ) unless $opt->{no_check};
        _print("\n");
    }

    my $str = _calc_stats($opt, $stats->{_total}->{$display});
    _print(_pad("Overall Avg $title:", 24)."$str\n");
}

sub _calc_stats {
    my $opt = shift;
    my $arr = shift;
    my $pad = shift;
    my ($min, $max, $avg) = _min_max_avg($arr);
    my $str = join '', map {_pad(sprintf($opt->{f}, $_), $pad)} ($avg,$min,$max);
    if ($opt->{stdev} && $avg) {
        my $stdev = _avg_stdev($arr);
        $stdev *= 100/$avg;
        $str .= _pad(sprintf("%0.2f%%", $stdev), $pad);
    }
    return $avg, $str;
}

sub _min_max_avg {
    my $arr = shift;
    return (0, 0, 0) unless @$arr;
    return min(@$arr), max(@$arr), sum(@$arr)/scalar(@$arr);
}

sub _avg_stdev {
    my $arr = shift;
    return (0, 0) unless @$arr;
    my $sum = sum(@$arr);
    my $avg = $sum/scalar(@$arr);
    my @sq;
    push @sq, ($avg - $_)**2 for (@$arr);
    my $dev = _min_max_avg(\@sq);
    return $avg, sqrt($dev);
}

# $single = single tail of dist curve outlier, 1 for over (right), -1 for under (left)
sub _drop_outliers {
    my $arr    = shift;
    my $single = shift;
    my ($avg, $stdev) = _avg_stdev($arr);
    my @newarr;
    foreach (@$arr) {
        if ($single) {
            push @newarr, $_ unless $single*($_ - $avg) > 2*$stdev;
        } else {
            push @newarr, $_ unless abs($avg - $_) > 2*$stdev;
        }
    }
    return @newarr;
}

sub _pad {
    my $str = shift;
    my $len = shift || 20;
    return $str." "x($len-length($str));
}

sub _printf {
    printf @_ unless $QUIET;
}

sub _print {
    print @_ unless $QUIET;
}

sub _get_time {
    return $MONO_CLOCK
        ? Time::HiRes::clock_gettime(CLOCK_MONOTONIC)
        : Time::HiRes::time();
}

sub _package_ver {
    my $pkg = __PACKAGE__;
    my $ver = $VERSION;

    my $caller = caller(0);
    for (my $i = 0; $i < 5; $i++) {
        my $caller = caller($i) or last;
        if ($caller eq 'Benchmark::DKbench') {
            $pkg = $caller;
            $ver = eval {$caller->VERSION} || '';
            last;
        }
    }

    return "$pkg v$ver";
}

1;