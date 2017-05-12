#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib ../Algorithm-Evolutionary/lib ); #Just in case we are testing it in-place

use Algorithm::MasterMind qw(check_combination);
use Algorithm::MasterMind::Test_Solver qw( solve_mastermind );

BEGIN {
	use_ok( 'Algorithm::MasterMind::Evo' );
}

my @secret_codes = qw( AAAA ABCD CDEF ACAC BAFE EFEF ABBB BAAC DEFF BFFF AAFF );

for my $secret_code ( @secret_codes ) {
  my $population_size = 256;
  my @alphabet = qw( A B C D E F );
  my $solver = new Algorithm::MasterMind::Evo 
  { alphabet => \@alphabet,
    length => length( $secret_code ),
    pop_size => $population_size,
    replacement_rate => 0.5 };

  solve_mastermind( $solver, $secret_code );

  # Other combination
  $solver = new Algorithm::MasterMind::Evo 
  { alphabet => \@alphabet,
    length => length( $secret_code ),
    pop_size => $population_size,
    replacement_rate => 0.4,
    distance => 'distance_chebyshev' };
  solve_mastermind( $solver, $secret_code );

  #Just another
  $solver = new Algorithm::MasterMind::Evo 
  { alphabet => \@alphabet,
      length => length( $secret_code ),
	pop_size => $population_size*2,
	  replacement_rate => 0.8,
	    played_out => 1 };
  solve_mastermind( $solver, $secret_code );
}

