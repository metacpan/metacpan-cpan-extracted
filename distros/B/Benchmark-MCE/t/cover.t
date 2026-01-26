use Test2::Tools::Exception qw/dies lives/;
use Test2::Mock;
use Test2::V0;
use Benchmark::MCE;
use Capture::Tiny 'capture';

sub func{select(undef, undef, undef, rand(0.3))};
my $bench = {
    Astro  => [\&func, '', 0.2, 1],
    Math   => [\&func, 1, 0.2, 2],
    Matrix => [\&func, 2, 0.2, 3],
    DCT    => [\&func, 3, 0.2, 4],
    prove  => [\&func, 4, 0.2, 5],
};

ok(dies {Benchmark::MCE::_bench_run('', 1)}, "No bench passed");

like(
    dies {
        suite_run({iter => 1})
    },
    qr/No benchmarks defined/,
    'No benchmarks defined'
);

like(
    dies {
        suite_run({iter => 1, bench => {}})
    },
    qr/No benchmarks defined/,
    'No benchmarks defined'
);

like(
    dies {
        suite_run({iter => 1, bench => {b1 => '$undef == 1'}})
    },
    qr/Error compiling benchmark/,
    'Bad code'
);

like(
    dies {
        suite_run({iter => 1, bench => {b1 => {}}})
    },
    qr/Error defining benchmark/,
    'Bad code'
);

like(
    dies {
        suite_run({iter => 1, exclude => 'pro', include => 'ove', bench => $bench})
    },
    qr/No tests/,
    'No tests to run'
);

like(
    dies { calc_scalability({}, {}) }, qr/thread count/, 'No thread count'
);

like(
    dies {calc_scalability({_opt => {threads => 1}}, {})},
    qr/thread count/,
    'No multi thread count'
);

like(
    dies {calc_scalability({_opt => {threads => 1}}, {_opt => {threads => 1}})},
    qr/thread count/,
    'Unequal thread count'
);

like(
    dies {
        calc_scalability({
                _opt => {
                    threads => 2,
                    scale   => 2
                }
            },
            {
                _opt => {
                    threads => 1,
                    scale   => 1
                }
            }
        )
    },
    qr/Same scale/,
    'Same scale expected'
);

like(
    dies {
        calc_scalability({
                _opt => {
                    threads => 1,
                    scale   => 1
                },
                test => {times => []},
            },
            {
                _opt => {
                    threads => 2,
                    scale   => 1
                },
            }
        )
    },
    qr/No bench times/,
    'Bench times expected'
);

like(
    dies {
        calc_scalability({
                _opt => {
                    threads => 1,
                    scale   => 1
                },
                test => {times => []},
            },
            {
                _opt => {
                    threads => 2,
                    scale   => 1
                },
                test => {times => []},
            }
        )
    },
    qr/No bench times/,
    'Bench times expected'
);

my @std = capture {
    calc_scalability({
            _opt => {
                threads => 1,
                scale   => 1,
                time    => 1
            },
            test   => {times => [10]},
            test2  => {times => [10]},
            _total => {times => [10]}
        },
        {
            _opt => {
                threads => 2,
                scale   => 1
            },
            test   => {times => [10]},
            test2  => {times => [10]},
            _total => {times => [10]}
        },
        1
    )
};

like($std[0], qr/(2 benchmarks, 2 threads)/, 'Two benches, two threads');

my @arr = (10, 11, 9, 10, 11, 10, 10, 10, 10, 10, 10);
is([Benchmark::MCE::_drop_outliers([@arr, 1, 19])], [@arr], 'Drop outliers');
is([Benchmark::MCE::_drop_outliers([@arr, 1, 19],1)], [@arr, 1], 'Drop right side outliers');
is([Benchmark::MCE::_drop_outliers([@arr, 1, 19],-1)], [@arr, 19], 'Drop left side outliers');
is([Benchmark::MCE::_avg_stdev([])], [0, 0], 'Empty array');
is([Benchmark::MCE::_min_max_avg([])], [0, 0, 0], 'Empty array');

{
    package Benchmark::DKbench;
    our $VERSION = '9.99';
    sub _probe_package_ver { Benchmark::MCE::_package_ver() }
}

is(Benchmark::DKbench::_probe_package_ver(), 'Benchmark::DKbench v9.99', 'DKbench caller in _package_ver');

my $mock = Test2::Mock->new(
    class => 'System::CPU',
    override => [ get_cpu => sub {} ]
);

is(system_identity(1), 1, 'System identity');

my @out = suite_calc({include => 'Astro', bench => $bench});
is(scalar @out, 1, 'Single Core result only');

my $mock2 = Test2::Mock->new(
    class => 'Benchmark::MCE',
    override => [ system_identity => sub {return 2} ]
);

@out = suite_calc({include => 'Astro', quick => '1', bench => $bench});
is(scalar @out, 3, 'Multi / Scalability results');

{
    my $mock3 = Test2::Mock->new(
        class => 'Benchmark::MCE',
        override => [ system_identity => sub {return 1} ]
    );
    @out = suite_calc({include => 'Astro', quick => '1', threads => 2, bench => $bench});
    is(scalar @out, 3, 'suite_calc threads option overrides system_identity');
}

@out = suite_calc({
        bench => {
            b1 => 'select(undef, undef, undef, rand(0.2))',
            b2 => sub {select(undef, undef, undef, rand(0.2))}
        }
    }
);
is(scalar @out, 3, 'Multi / Scalability results');

sub func0{return 0};
sub func1{return 1};

like(dies {suite_run({filter =>\&func0, bench => $bench})}, qr/No tests to run/,'Filtered out');

$Benchmark::MCE::MONO_CLOCK = 0;
my %stat = suite_run({filter =>\&func1, bench => $bench, srand => 0});
is(scalar(keys %stat), scalar(keys %$bench)+2, 'None filtered');

done_testing();
