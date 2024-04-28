use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;
use Benchmark::DKbench;
use Capture::Tiny 'capture';

ok(dies {Benchmark::DKbench::bench_run('', 1)}, "No bench passed");

like(
    dies {
        suite_run({iter => 1, exclude => 'Moose', include => 'prove', sleep => 1})
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
        }
    )
};

like($std[0], qr/(2 benchmarks, 2 threads)/, 'Two benches, two threads');

is(Benchmark::DKbench::compare_hash({a=>1}, {a=>1, b=>1}), 0, 'Different num keys');
is(Benchmark::DKbench::compare_hash({a=>1, b=>2}, {a=>1, b=>1}), 0, 'Different values');
is(Benchmark::DKbench::compare_arr([1, 2], [1]), 0, 'Different size array');
is(Benchmark::DKbench::compare_arr([1, 2], [1, 1]), 0, 'Different vals array');
is(Benchmark::DKbench::compare_obj([], {}), 0, 'Different types of obj');
is([Benchmark::DKbench::_decode_jwt2(token=>1,decode_header=>1)], [undef, undef], 'No token');
my @arr = (10, 11, 9, 10, 11, 10, 10, 10, 10, 10, 10);
is([Benchmark::DKbench::drop_outliers([@arr, 1, 19])], [@arr], 'Drop outliers');
is([Benchmark::DKbench::drop_outliers([@arr, 1, 19],1)], [@arr, 1], 'Drop right side outliers');
is([Benchmark::DKbench::drop_outliers([@arr, 1, 19],-1)], [@arr, 19], 'Drop left side outliers');
is([Benchmark::DKbench::avg_stdev([])], [0, 0], 'Empty array');
is([Benchmark::DKbench::min_max_avg([])], [0, 0, 0], 'Empty array');
is(length(Benchmark::DKbench::_random_str()), 1, 'Default len 1');

$Benchmark::DKbench::datadir = '';

ok(dies {Benchmark::DKbench::bench_imager(1)}, "No image file found");

my $mock = Test2::Mock->new(
    class => 'System::CPU',
    override => [ get_cpu => sub {} ]
);

is(system_identity(1), 1, 'System identity');

is(Benchmark::DKbench::benchmark_list(), Benchmark::DKbench::benchmark_list({}), 'benchmark_list');

done_testing();