use Test2::V0;
use Benchmark::DKbench;
use Capture::Tiny 'capture';
use File::ShareDir 'dist_dir';

my $threads;
my @std = capture {$threads = system_identity()};
like($std[0], qr/CPU/, 'System identity');
diag $std[0];

my %opt = (
    skip_bio   => 1,
    time_piece => 1,
    quick      => 1,
    ver        => 2.1,
    exclude    => 'Math'
);
my (%stats1, %stats2, %scal);
@std = capture {%stats1 = suite_run({%opt, no_mce=>1})};
like($std[0], qr/Overall Time/, 'Bench');
diag $std[0];

if ($threads && $threads > 1) {
    $opt{include} = 'Astro';
    $opt{ver}     = 1;
    @std          = capture {%stats2 = suite_run({%opt, threads => 2})};
    diag $std[0];
} else {
    $stats2{$_} = {%{$stats1{$_}}} for qw/Astro _opt _total/;
    $stats2{_opt}->{threads} = 2;
}

@std = capture {%scal = calc_scalability(\%stats1, \%stats2)};

like($std[0], qr/scalability/, 'Scalability');
diag $std[0];

is([sort keys %scal], [qw/Astro _total/], 'Expected scal keys');

@std = capture {
    %stats1 = suite_run({
            threads    => 1,
            skip_prove => 1,
            bio_codons => 1,
            scale      => 1,
            iter       => 2,
            stdev      => 1,
            no_mce     => 1,
            include    => 'Matrix'
        }
    )
};
like($std[0], qr/Overall Avg Score/, 'Aggregate');
diag $std[0];

%stats2 = %stats1;
$stats2{_opt} = {%{$stats1{_opt}}};
$stats2{_opt}->{threads} = 2;
calc_scalability(\%stats1, \%stats2);

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
            threads => 1,
            quick   => 1,
            iter    => 2,
            no_mce  => 1,
            include => 'DCT',
        }
    )
};
like($std[0], qr/2 iterations\)/, 'Aggregate');

my $datadir = dist_dir("Benchmark-DKbench");

@std = capture {
    suite_run({
            datapath => $datadir,
            time     => 1,
            iter     => 1,
            no_mce   => 1,
            sleep    => 1,
            include  => 'prove',
        }
    )
};
like($std[0], qr/Overall Time/, 'Single');

done_testing();
