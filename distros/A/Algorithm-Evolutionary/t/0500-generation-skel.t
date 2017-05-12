#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test;
BEGIN { plan tests => 4 };
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw( Individual::BitString 
				Op::Mutation Op::Crossover
				Op::RouletteWheel
				Fitness::ONEMAX Op::Generation_Skeleton
				Op::Replace_Worst
				Op::Replace_Different);

use Algorithm::Evolutionary::Utils qw(average);

#########################

my $onemax = new Algorithm::Evolutionary::Fitness::ONEMAX;

my @pop;
my $number_of_bits = 20;
my $population_size = 20;
my $replacement_rate = 0.5;
for ( 1..$population_size ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits ; #Creates random individual
  $indi->evaluate( $onemax );
  push( @pop, $indi );
}

my $m =  new Algorithm::Evolutionary::Op::Mutation 0.5;
my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover

my $selector = new Algorithm::Evolutionary::Op::RouletteWheel $population_size; #One of the possible selectors

my $generation = 
  new Algorithm::Evolutionary::Op::Generation_Skeleton( $onemax, $selector, [$m, $c], $replacement_rate );

my @sorted_pop = sort { $b->Fitness() <=> $a->Fitness() } @pop;
my $bestIndi = $sorted_pop[0];
my $previous_average = average( \@sorted_pop );
$generation->apply( \@sorted_pop );
ok( $bestIndi->Fitness() <= $sorted_pop[0]->Fitness(), 1 ); #fitness
                                                         #improves,
                                                         #but not
                                                         #always 
#This should have improved...
do {
  $generation->apply( \@sorted_pop );
} until ( $previous_average < average( \@sorted_pop)); #It eventually improves

my $this_average = average( \@sorted_pop );
ok( $previous_average < $this_average , 1 );

my $replacer = new Algorithm::Evolutionary::Op::Replace_Worst; 

my $new_generation = 
  new Algorithm::Evolutionary::Op::Generation_Skeleton( $onemax, $selector, [$m, $c], $replacement_rate, $replacer );

do {
  $new_generation->apply( \@sorted_pop );
} until ( $this_average < average( \@sorted_pop)); #It eventually improves

ok( $this_average < average( \@sorted_pop), 1 );

$replacer = new Algorithm::Evolutionary::Op::Replace_Different; 

$new_generation = 
  new Algorithm::Evolutionary::Op::Generation_Skeleton( $onemax, $selector, [$m, $c], $replacement_rate, $replacer );

do {
  $new_generation->apply( \@sorted_pop );
} until ( $this_average < average( \@sorted_pop)); #It eventually improves

ok( $this_average < average( \@sorted_pop), 1 );

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/08/12 09:08:47 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/0500-generation-skel.t,v 3.2 2011/08/12 09:08:47 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.2 $
  $Name $

=cut
