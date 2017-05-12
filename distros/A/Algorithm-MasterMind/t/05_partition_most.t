#!perl 

use Test::More qw( no_plan ); #Random initial string...
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Algorithm::MasterMind qw(check_combination);

BEGIN {
	use_ok( 'Algorithm::MasterMind::Partition_Most' );
}

my $secret_code = 'ADCB';
my @alphabet = qw( A B C D E F );
my $solver = new Algorithm::MasterMind::Partition_Most { alphabet => \@alphabet,
							  length => length( $secret_code ) };

isa_ok( $solver, 'Algorithm::MasterMind::Partition_Most', 'Instance OK' );
diag( "This might take a while while it finds the code $secret_code" );
my $first_string = $solver->issue_first;
diag( "This might take a while while it finds the second move" );
is( length( $first_string), 4, 'Issued first '. $first_string );
$solver->feedback( check_combination( $secret_code, $first_string) );
is( scalar $solver->number_of_rules, 1, "Rules added" );
my $played_string = $solver->issue_next;
while ( $played_string ne $secret_code ) {
  is( length( $played_string), 4, 'Playing '. $played_string ) ;
  $solver->feedback( check_combination( $secret_code, $played_string) );
  isnt( $solver->{'_partitions'}->partitions_for('ADCB'), undef, 'Way to go' );
  $played_string = $solver->issue_next;
}
is( $played_string, $secret_code, "Found code after ".$solver->evaluated()." combinations" );
