use Test2::V0;
use Benchmark::DKbench;
use Math::Trig qw/:great_circle :pi/;

sub great_circle {
    my $iter = shift || 1;
    my $dist = 0;
    $dist +=
        great_circle_distance(rand(pi), rand(2 * pi), rand(pi), rand(2 * pi)) -
        great_circle_bearing(rand(pi), rand(2 * pi), rand(pi), rand(2 * pi)) +
        great_circle_direction(rand(pi), rand(2 * pi), rand(pi), rand(2 * pi))
        for 1 .. $iter;
    return $dist;
}

my %stats = suite_run({
        time        => 1,
        threads     => 1,
        include     => 'Math::Trig',
        extra_bench => { 'Math::Trig' => [\&great_circle, 'x', 1]}
    }
);

ok($stats{'Math::Trig'}->{scores} > 0, 'Custom bench scored') or diag(\%stats);

%stats = suite_run({
        include     => 'custom',
        extra_bench => {
            'custom1' => [sub {my @a=split(//, 'x'x$_) for 1..100}, 1, 1],
            'custom2' => [sub {my @a=split(//, 'x'x$_) for 1..100}, 1, 0],
            'custom3' => [sub {my @a=split(//, 'x'x$_) for 1..100}]
        }
    }
);

ok($stats{custom1}->{scores} > 0, 'Custom bench still scored') or diag(\%stats);

done_testing();
