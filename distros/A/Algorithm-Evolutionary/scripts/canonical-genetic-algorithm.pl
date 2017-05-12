#!/usr/bin/perl

=head1 NAME

canonical-genetic-algorithm.pl - Canonical Genetic Algorithm on a simple fitness function

=head1 SYNOPSIS

  prompt% ./canonical-genetic-algorithm.pl <bits> <block size> <population> <number of generations> <selection rate>


=head1 DESCRIPTION  

A canonical GA uses mutation, crossover, binary representation, and
    roulette wheel selection. Here mainly for reference, and so that
    you can peruse to start your own programs.

In this case, we are optimizing the Royal Road function,
L<http://web.cecs.pdx.edu/~mm/handbook-of-ec-rr.pdf>. By default,
these values are used:

=over

=item * 

I<number of bits>: 64 (this is the chromosome length)

=item * 

I<size of block>: 4 (RR goes by blocks)

=item * 

I<population size>: 256

=item * 

I<number of generations>: 200 (could end before, if solution is
found) 

=item * 

I<selection rate>: 20% (will be replaced each generation); this means it's a steady state algorithm, which only changes a part of the population each generation.

=back

This program also demonstrates the use of caches in the fitness
evaluation, so be careful if you use too many bits or too many
generations, check the memory.

Output shows the number of generations, the winning chromosome, and
fitness. After finishing, it outputs time, cache ratio and some other
things. 

=cut

use warnings;
use strict;

use Time::HiRes qw( gettimeofday tv_interval); #for benchmarking

use lib qw(lib ../lib);
#Importing all neded modules using the short POE-ish version
use Algorithm::Evolutionary qw( Individual::BitString Op::Creator 
				Op::CanonicalGA Op::Bitflip 
				Op::Crossover Fitness::Royal_Road);
use Algorithm::Evolutionary::Utils qw(entropy consensus);

#----------------------------------------------------------#
my $bits = shift || 64;
my $block_size = shift || 4;
my $pop_size = shift || 256; #Population size
my $numGens = shift || 200; #Max number of generations
my $selection_rate = shift || 0.2;


#----------------------------------------------------------#
#Initial population
my @pop;
my $creator = new Algorithm::Evolutionary::Op::Creator( $pop_size, 'BitString', { length => $bits });
$creator->apply( \@pop ); #Generates population

#----------------------------------------------------------#
# Variation operators
my $m = Algorithm::Evolutionary::Op::Bitflip->new( 1 );
my $c = Algorithm::Evolutionary::Op::Crossover->new(2, 4);

# Fitness function: create it and evaluate
my $rr = new  Algorithm::Evolutionary::Fitness::Royal_Road( $block_size );
map( $_->evaluate( $rr ), @pop ); 

#----------------------------------------------------------#
#Usamos estos operadores para definir una generación del algoritmo. Lo cual
# no es realmente necesario ya que este algoritmo define ambos operadores por
# defecto. Los parámetros son la función de fitness, la tasa de selección y los
# operadores de variación.
my $generation = Algorithm::Evolutionary::Op::CanonicalGA->new( $rr , $selection_rate , [$m, $c] ) ;

#Time, counter and do the do
my $inicioTiempo = [gettimeofday()];
my $contador=0;
do {
  $generation->apply( \@pop );
  print "$contador : ", $pop[0]->asString(), "\n" ;
  $contador++;
} while( ($contador < $numGens) 
	 && ($pop[0]->Fitness() < $bits));


#----------------------------------------------------------#
# Show best
print "Best is:\n\t ",$pop[0]->asString()," Fitness: ",$pop[0]->Fitness(),"\n";

print "\n\n\tTime: ", tv_interval( $inicioTiempo ) , "\n";

print "\n\tEvaluations: ", $rr->evaluations(), "\n";

print "\n\tCache size ratio: ", $rr->cached_evals()/$rr->evaluations(), "\n";

=head1 SEE ALSO


First, you should obviously check
    L<Algorithm::Evolutionary::Op::CanonicalGA>, and then these other classes.

=over 4

=item *

L<Algorithm::Evolutionary::Op::Base>.

=item *

L<Algorithm::Evolutionary::Individual::Base>.

=item *

L<Algorithm::Evolutionary::Fitness::Base>.

=item *

L<Algorithm::Evolutionary::Experiment>.

=item *

L<XML>

=back

=head1 AUTHOR

J. J. Merelo, C<jj (at) merelo.net>

=cut

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/30 07:48:48 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/scripts/canonical-genetic-algorithm.pl,v 3.1 2009/07/30 07:48:48 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $


=cut
