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
        threads     => 1,
        include     => 'Math::Trig',
        extra_bench => { 'Math::Trig' => ['3144042.81433949', 5.5, \&great_circle, 400000, 2000000]}        
    }
);

ok($stats{'Math::Trig'}->{scores} > 0, 'Custom bench scored') or diag(\%stats);

done_testing();
