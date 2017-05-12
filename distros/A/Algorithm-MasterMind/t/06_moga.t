#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib ../Algorithm-Evolutionary/lib ); #Just in case we are testing it in-place

use Algorithm::MasterMind qw(check_combination);

BEGIN {
	use_ok( 'Algorithm::MasterMind::Evolutionary_MO' );
}

my $secret_code = 'EAFC';
my $population_size = 300;
my $length = length( $secret_code );
my @alphabet = qw( A B C D E F );
my $solver = new Algorithm::MasterMind::Evolutionary_MO { alphabet => \@alphabet,
						       length => $length,
						       pop_size => $population_size,
						       replacement_rate => 0.2};

isa_ok( $solver, 'Algorithm::MasterMind::Evolutionary_MO', 'Instance OK' );

 my $first_string = $solver->issue_first;
diag( "This might take a while while it finds the code $secret_code" );
is( length( $first_string), $length, 'Issued first '. $first_string );
$solver->feedback( check_combination( $secret_code, $first_string) );
my $played_string = $solver->issue_next;
is( length( $played_string), $length, 'Playing '. $played_string ) ;


