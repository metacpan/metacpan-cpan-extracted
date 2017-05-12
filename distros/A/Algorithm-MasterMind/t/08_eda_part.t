#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib ../Algorithm-Evolutionary/lib ); #Just in case we are testing it in-place

use Algorithm::MasterMind qw(check_combination);

BEGIN {
	use_ok( 'Algorithm::MasterMind::EDA_Partitions' );
}


my @secret_codes = qw( AAAA ABCD CDEF ACAC BAFE FFFF);

for my $secret_code ( @secret_codes ) {
  my $population_size = 256;
  my @alphabet = qw( A B C D E F );
  my $solver = new Algorithm::MasterMind::EDA_Partitions { alphabet => \@alphabet,
							     length => length( $secret_code ),
							       pop_size => $population_size,
								 replacement_rate => 0.2 };

  solve_mastermind( $solver, $secret_code );
}

sub solve_mastermind {
  my $solver = shift;
  my $secret_code = shift;
  my $length = length( $secret_code );
  my $first_string = $solver->issue_first;
  diag( "This might take a while while it finds the code $secret_code" );
  is( length( $first_string), $length, 'Issued first '. $first_string );
  $solver->feedback( check_combination( $secret_code, $first_string) );
  my $played_string = $solver->issue_next;
  while ( $played_string ne $secret_code ) {
      is( length( $played_string), $length, 'Playing '. $played_string ) ;
      $solver->feedback( check_combination( $secret_code, $played_string) );
      $played_string = $solver->issue_next;
  }
  is( $played_string, $secret_code, "Found code after ".$solver->evaluated()." combinations" );
}
