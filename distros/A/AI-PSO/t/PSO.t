use Test::More tests => 9;
BEGIN { use_ok('AI::PSO') };

my %test_params = (
	numParticles   => 4,
	numNeighbors   => 3,
	maxIterations  => 5000,
	dimensions     => 4,
	deltaMin       => -2.0,
	deltaMax       =>  4.0,
	meWeight       => 2.0,
	meMin          => 0.0,
	meMax          => 1.0,
	themWeight     => 2.0,
	themMin        => 0.0,
	themMax        => 1.0,
	exitFitness    => 0.99,
	verbose        => 1,
);

my %test_params2 = %test_params;
$test_params2{psoRandomRange} = 4.0;

# simple test function to sum the position values up to 3.5
my $testValue = 3.5;
sub test_fitness_function(@) {
        my (@arr) = (@_);
        my $sum = 0;
	my $ret = 0;
        foreach my $val (@arr) {
                $sum += $val;
        }
	# sigmoid-like ==> squash the result to [0,1] and get as close to 3.5 as we can
	return 2 / (1 + exp(abs($testValue - $sum)));

	return $ret;
}


ok( pso_set_params(\%test_params) == 0 );
ok( pso_register_fitness_function('test_fitness_function') == 0 );
ok( pso_optimize() == 0 );
my @solution = pso_get_solution_array();
ok( $#solution == $test_params{numParticles} - 1 );

ok( pso_set_params(\%test_params2) == 0 );
ok( pso_register_fitness_function('test_fitness_function') == 0 );
ok( pso_optimize() == 0 );
my @solution2 = pso_get_solution_array();
ok( $#solution2 == $test_params2{numParticles} - 1 );
