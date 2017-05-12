#-*-cperl-*-


use Test::More tests => 9;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use_ok( "Algorithm::Evolutionary::Run", "using A::E::Run OK" );
my $path= 't';
if ( ! -e "$path/p_peaks.yaml" ) {
  $path = '.'; # Just in case we're testing in-dir
}

my $algorithm = new Algorithm::Evolutionary::Run "$path/p_peaks.yaml";
isa_ok( $algorithm, 'Algorithm::Evolutionary::Run' );
$algorithm->{'_counter'} = 0;
$algorithm->step();
ok( $algorithm->{'_counter'} == 1, "step OK" ); 
my $conf = {
  'fitness' => {
    'class' => 'MMDP'
  },
  'crossover' => {
    'priority' => '3',
    'points' => '2'
  },
  'max_generations' => '10',
  'mutation' => {
    'priority' => '2',
    'rate' => '0.1'
  },
  'length' => '120',
  'max_fitness' => '20',
  'pop_size' => '128',
  'selection_rate' => '0.1'
};
my $another_algorithm = new Algorithm::Evolutionary::Run $conf;
isa_ok( $another_algorithm, 'Algorithm::Evolutionary::Run' );
my $somebody = $algorithm->random_member();
isa_ok( $somebody, 'Algorithm::Evolutionary::Individual::BitString');
$another_algorithm->run();
ok( $another_algorithm->{'_counter'} == 10, "run OK" ); 
my $results = $another_algorithm->results();
cmp_ok( $results->{'evaluations'}, ">",100, "Evaluations OK" );
cmp_ok( $results->{'best'}->Fitness(), ">", 
	$results->{'last_good'}->Fitness(), "Evolution OK" );
cmp_ok( $another_algorithm->compute_average_distance( $somebody), ">", 0, "Distances" );
