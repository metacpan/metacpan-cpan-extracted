#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib ../Algorithm-Evolutionary/lib ); #Just in case we are testing it in-place

use Algorithm::MasterMind qw(check_combination);
use Algorithm::MasterMind::Test_Solver qw( solve_mastermind );

BEGIN {
	use_ok( 'Algorithm::MasterMind::EvoRank' );
}


my @secret_codes = qw( AAAA ABCD CDEF ACAC BAFE FFFF);
my @stats;
my @alphabet = qw( A B C D E F );
my $population_size = 256;

for my $secret_code ( @secret_codes ) {

  my $solver = new Algorithm::MasterMind::EvoRank { alphabet => \@alphabet,
						      length => length( $secret_code ),
							pop_size => $population_size,
							  replacement_rate => 0.5 };

  push @{$stats[0]}, solve_mastermind( $solver, $secret_code );
  $solver = new Algorithm::MasterMind::EvoRank { alphabet => \@alphabet,
						      length => length( $secret_code ),
							pop_size => $population_size,
							    distance => 'distance_chebyshev' };
  push @{$stats[1]}, solve_mastermind( $solver, $secret_code );

  $solver = new Algorithm::MasterMind::EvoRank { alphabet => \@alphabet,
						   length => length( $secret_code ),
						     pop_size => $population_size,
						       permutation_rate => 2 };
  push @{$stats[2]}, solve_mastermind( $solver, $secret_code );

  $solver = new Algorithm::MasterMind::EvoRank { alphabet => \@alphabet,
						   length => length( $secret_code ),
						     pop_size => $population_size,
						       permutation_rate => 1,
							  replacement_rate => 0.3,
							    crossover_rate => 8};
  push @{$stats[3]}, solve_mastermind( $solver, $secret_code );
}

for my $s (@stats) {
  my ($combinations, $games);
  for my $i ( @$s ) {
    $combinations += $i->[0];
    $games += $i->[1];
  }
  diag( "Average combinations " . $combinations / @$s  . " Games " . $games / @$s );
}
