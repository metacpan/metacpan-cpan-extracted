use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;
use Benchmark::DKbench;

ok(dies {Benchmark::DKbench::bench_run('', 1)}, "No bench passed");

like(
    dies {
        suite_run({iter => 1, exclude => 'Moose', include => 'prove', sleep => 1})
    },
    qr/No tests/,
    'No tests to run'
);

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

like(dies {Benchmark::DKbench::bench_imager(1)}, qr/file/, "No image file found");

done_testing();