use Test2::V0;
use Benchmark::MCE;
use Capture::Tiny 'capture';

# Test adapted from Benchmark::DKbench

my $threads;
my @std = capture {$threads = system_identity()};
like($std[0], qr/CPU/, 'System identity');

sub func{select(undef, undef, undef, rand(0.3))};
my $bench = {
    Astro  => [\&func, undef, 0.2],
    Math   => [\&func, undef, 0.2],
    Matrix => [\&func, undef, 0.2],
    DCT    => [\&func, undef, 0.2],
    prove  => [\&func, undef, 0.2],
};

my %opt = (
    quick      => 1,
    exclude    => 'Math',
    bench      => $bench
);
my (%stats1, %stats2, %scal);
@std = capture {%stats1 = suite_run({%opt, no_mce=>1})};
like($std[0], qr/Overall Time/, 'Bench');

if ($threads && $threads > 1) {
    $opt{include} = 'Astro';
    @std          = capture {%stats2 = suite_run({%opt, threads => 2})};
} else {
    $stats2{$_} = {%{$stats1{$_}}} for qw/Astro _opt _total/;
    $stats2{_opt}->{threads} = 2;
}

@std = capture {%scal = calc_scalability(\%stats1, \%stats2)};

like($std[0], qr/scalability/, 'Scalability');

is([sort keys %scal], [qw/Astro _total/], 'Expected scal keys');

@std = capture {
    %stats1 = suite_run({
            threads => 1,
            scale   => 1,
            iter    => 2,
            stdev   => 1,
            no_mce  => 1,
            include => 'Matrix',
            bench   => $bench
        }
    )
};

like($std[0], qr/Overall Avg Score/, 'Aggregate');

%stats2 = %stats1;
$stats2{_opt} = {%{$stats1{_opt}}};
$stats2{_opt}->{threads} = 2;
@std = capture {calc_scalability(\%stats1, \%stats2)};
like($std[0], qr/Single:\s*\d+\s*\(\d+ - \d+/, 'Min Max');

$stats1{_opt}->{iter} = 1;
@std = capture {calc_scalability(\%stats1, \%stats2)};

unlike($std[0], qr/scale/, 'No scale listed');
unlike($std[0], qr/iterations/, 'No iterations listed');

$stats1{_opt}->{iter}  = 2;
$stats1{_opt}->{time}  = 1;
$stats1{_opt}->{scale} = 2;
$stats2{_opt}->{scale} = 2;
@std = capture {calc_scalability(\%stats2, \%stats1)};

like($std[0], qr/scale/, 'Scale listed');
like($std[0], qr/iterations/, 'Iterations listed');

@std = capture {
    suite_run({
        threads    => 1,
        quick      => 1,
        iter       => 2,
        no_mce     => 1,
        include    => 'DCT',
        benchmarks => $bench
    })
};
like($std[0], qr/2 iterations\)/, 'Aggregate');

@std = capture {
    suite_run({
        time        => 1,
        iterations  => 1,
        duration    => 1,
        no_mce      => 1,
        sleep       => 1,
        include     => 'prove',
        extra_bench => $bench
    })
};

like($std[0], qr/Overall Time/, 'Single');
like($std[0], qr/0s of 1s/, 'Duration');

$Benchmark::MCE::QUIET = 1;
@std = capture {$threads = system_identity()};
is($std[0], '', 'No output');

pop @{$bench->{Astro}};
$bench->{Math}->[2]  = 0;
$bench->{$_}->[1] = 'x' for keys %$bench;
@std = capture {
    suite_run({bench => $bench, iter => 2})
};

is($std[0], '', 'No output');
diag $std[0];

done_testing();
