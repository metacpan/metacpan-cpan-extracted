#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib ../Algorithm-Evolutionary/lib ); #Just in case we are testing it in-place

use Algorithm::MasterMind qw(check_combination);

BEGIN {
	use_ok( 'Algorithm::MasterMind::Evolutionary' );
}

my $secret_code = 'EAFC';
my $population_size = 256;
my $length = length( $secret_code );
my @alphabet = qw( A B C D E F );
my $solver = new Algorithm::MasterMind::Evolutionary { alphabet => \@alphabet,
						       length => length( $secret_code ),
						       pop_size => $population_size};

solve_mastermind( $solver, $secret_code );

sub solve_mastermind {
  my $solver = shift;
  my $secret_code = shift;
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
