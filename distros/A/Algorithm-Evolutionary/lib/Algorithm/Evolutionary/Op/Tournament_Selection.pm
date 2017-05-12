use strict; #-*-cperl-*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Op::Tournament_Selection - Tournament selector, takes individuals from one population and puts them into another

=head1 SYNOPSIS

  my $popSize = 100;
  my $tournamentSize = 7;
  my $selector = new Algorithm::Evolutionary::Op::Tournament_Selection $tournamentSize;
  my @newPop = $selector->apply( @pop ); #Creates a new population from old

=head1 Base Class

L<Algorithm::Evolutionary::Op::Selector>

=head1 DESCRIPTION

One of the possible selectors used for selecting the pool of individuals
that are going to be the parents of the following generation. Takes a
set of individuals randomly out of the population, and select  the best. 

=head1 METHODS

=cut


package Algorithm::Evolutionary::Op::Tournament_Selection;

use Carp;

our $VERSION = '1.5';

use base 'Algorithm::Evolutionary::Op::Base';

=head2 new( $output_population_size, $tournament_size )

Creates a new tournament selector

=cut

sub new {
  my $class = shift;
  my $self = Algorithm::Evolutionary::Op::Base::new($class );
  $self->{'_tournament_size'} = shift || 2;
  bless $self, $class;
  return $self;
}

=head2 apply( $ref_to_population[, $output_size || @$ref_to_population] )

Applies the tournament selection to a population, returning another of
the same size by default or whatever size is selected. Please bear in
mind that, unlike other selectors, this one uses a reference to
population instead of a population array. 

=cut

sub apply ($$) {
  my $self = shift;
  my $pop = shift || croak "No pop";
  my $output_size = shift || @$pop;
  my @output;
  for ( my $i = 0; $i < $output_size; $i++ ) {
    #Randomly select a few guys
    my $best = $pop->[ rand( @$pop ) ];
    for ( my $j = 1; $j < $self->{'_tournament_size'}; $j++ ) {
      my $this_one = $pop->[ rand( @$pop ) ];
      if ( $this_one->{'_fitness'} > $best->{'_fitness'} ) {
	$best = $this_one;
      }
    }
    #Sort by fitness
    push @output, $best;
  }
  return @output;
}

=head1 See Also

L<Algorithm::Evolutionary::Op::RouleteWheel> is another option for
selecting a pool of individuals

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"The truth is in here";
