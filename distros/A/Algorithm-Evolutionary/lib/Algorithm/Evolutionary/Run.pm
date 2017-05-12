use strict; #-*-cperl-*-
use warnings;

use lib qw(../../.. ../.. ); #Emacs does not allow me to save!!!

=head1 NAME

Algorithm::Evolutionary::Run - Class for setting up an experiment with algorithms and population
                 
=head1 SYNOPSIS
  
  use Algorithm::Evolutionary::Run;

  my $algorithm = new Algorithm::Evolutionary::Run 'conf.yaml';
  #or
  my $conf = {
    'fitness' => {
      'class' => 'MMDP'
    },
    'crossover' => {
      'priority' => '3',
      'points' => '2'
     },
    'max_generations' => '1000',
    'mutation' => {
      'priority' => '2',
      'rate' => '0.1'
    },
    'length' => '120',
    'max_fitness' => '20',
    'pop_size' => '1024',
    'selection_rate' => '0.1'
  };

  my $algorithm = new Algorithm::Evolutionary::Run $conf;

  #Run it to the end
  $algorithm->run();
  
  #Print results
  $algorithm->results();
  
  #A single step
  $algorithm->step();
  
=head1 DESCRIPTION

This is a no-fuss class to have everything needed to run an algorithm
    in a single place, although for the time being it's reduced to
    fitness functions in the A::E::F namespace, and binary
    strings. Mostly for demo purposes, but can be an example of class
    for other stuff.

=cut

=head1 METHODS

=cut

package Algorithm::Evolutionary::Run;

use Algorithm::Evolutionary qw(Individual::BitString Op::Easy Op::CanonicalGA 
			       Op::Bitflip Op::Crossover 
			       Op::Gene_Boundary_Crossover);
 
use Algorithm::Evolutionary::Utils qw(hamming);

our $VERSION =  '3.2' ;

use Carp;
use YAML qw(LoadFile);
use Time::HiRes qw( gettimeofday tv_interval);

=head2 new( $algorithm_description )

Creates the whole stuff needed to run an algorithm. Can be called from a hash with t 
   options, as per the example. All of them are compulsory. See also the C<examples> subdir for examples of the YAML conf file. 

=cut

sub new {
  my $class = shift;

  my $param = shift;
  my $fitness_object = shift; # Can be undef
  my $self;
  if ( ! ref $param ) { #scalar => read yaml file
      $self = LoadFile( $param ) || carp "Can't load $param: is it a file?\n";
  } else { #It's a hashref
      $self = $param;
  }
  
#----------------------------------------------------------#
# Variation operators
  my $m = new Algorithm::Evolutionary::Op::Bitflip( 1, $self->{'mutation'}->{'priority'}  );
  my $c;
  #Big hack here
  if ( $self->{'crossover'} ) {
    $c = new Algorithm::Evolutionary::Op::Crossover($self->{'crossover'}->{'points'}, $self->{'crossover'}->{'priority'} );
  } elsif ($self->{'gene_boundary_crossover'}) {
    $c = new Algorithm::Evolutionary::Op::Gene_Boundary_Crossover($self->{'gene_boundary_crossover'}->{'points'}, 
								  $self->{'gene_boundary_crossover'}->{'gene_size'} , 
								  $self->{'gene_boundary_crossover'}->{'priority'} );
  } elsif ($self->{'quad_xover'} ) {
    $c = new Algorithm::Evolutionary::Op::QuadXOver($self->{'crossover'}->{'points'}, $self->{'crossover'}->{'priority'} );
  }
  
# Fitness function
  if ( !$fitness_object ) {
    my $fitness_class = "Algorithm::Evolutionary::Fitness::".$self->{'fitness'}->{'class'};
    eval  "require $fitness_class" || die "Can't load $fitness_class: $@\n";
    my @params = $self->{'fitness'}->{'params'}? @{$self->{'fitness'}->{'params'}} : ();
    $fitness_object = eval $fitness_class."->new( \@params )" || die "Can't instantiate $fitness_class: $@\n";
  }
  $self->{'_fitness'} = $fitness_object;
  
#----------------------------------------------------------#
#Usamos estos operadores para definir una generación del algoritmo. Lo cual
# no es realmente necesario ya que este algoritmo define ambos operadores por
# defecto. Los parámetros son la función de fitness, la tasa de selección y los
# operadores de variación.
  my $algorithm_class = "Algorithm::Evolutionary::Op::".($self->{'algorithm'}?$self->{'algorithm'}:'Easy');
  my $generation = eval $algorithm_class."->new( \$fitness_object , \$self->{'selection_rate'} , [\$m, \$c] )" 
    || die "Can't instantiate $algorithm_class: $@\n";;
  
#Time
  my $inicioTiempo = [gettimeofday()];
  
#----------------------------------------------------------#
  bless $self, $class;
  $self->reset_population;
  for ( @{$self->{'_population'}} ) {
    if ( !defined $_->Fitness() ) {
      $_->evaluate( $fitness_object );
    }
  }

  $self->{'_generation'} = $generation;
  $self->{'_start_time'} = $inicioTiempo;
  return $self;
}

=head2 population_size( $new_size )

Resets the population size to the C<$new_size>. It does not do
anything to the actual population, just resests the number. You should
do a C<reset_population> afterwards.

=cut

sub population_size {
  my $self = shift;
  my $new_size = shift || croak "Too small!";
  $self->{'pop_size'} = $new_size;
}


=head2 reset_population()

Resets population, creating a new one; resets fitness counter to 0

=cut 

sub reset_population {
  my $self = shift;
  #Initial population
  my @pop;

  #Creamos $popSize individuos
  my $bits = $self->{'length'}; 
  for ( 1..$self->{'pop_size'} ) {
      my $indi = Algorithm::Evolutionary::Individual::BitString->new( $bits );
      $indi->evaluate( $self->{'_fitness'} );
      push( @pop, $indi );
  }
  $self->{'_population'} = \@pop;
  $self->{'_fitness'}->reset_evaluations;
}

=head2 step()

Runs a single step of the algorithm, that is, a single generation 

=cut

sub step {
    my $self = shift;
    $self->{'_generation'}->apply( $self->{'_population'} );
    $self->{'_counter'}++;
}

=head2 run()

Applies the different operators in the order that they appear; returns the population
as a ref-to-array.

=cut

sub run {
  my $self = shift;
  $self->{'_counter'} = 0;
  do {
      $self->step();
      
  } while( ($self->{'_counter'} < $self->{'max_generations'}) 
	 && ($self->{'_population'}->[0]->Fitness() < $self->{'max_fitness'}));

}

=head2 random_member()

Returns a random guy from the population

=cut

sub random_member {
    my $self = shift;
    return $self->{'_population'}->[rand( @{$self->{'_population'}} )];
}

=head2 results()
 
Returns results in a hash that contains the best, total time so far
 and the number of evaluations. 

=cut

sub results {
  my $self = shift;
  my $population_size = scalar @{$self->{'_population'}};
  my $last_good_pos = $population_size*(1-$self->{'selection_rate'});
  my $results = { best => $self->{'_population'}->[0],
		  median => $self->{'_population'}->[ $population_size / 2],
		  last_good => $self->{'_population'}->[ $last_good_pos ],
		  time =>  tv_interval( $self->{'_start_time'} ),
		  evaluations => $self->{'_fitness'}->evaluations() };
  return $results;

}

=head2 evaluated_population()

Returns the portion of population that has been evaluated (all but the new ones)

=cut 

sub evaluated_population {
  my $self = shift;
  my $population_size = scalar @{$self->{'_population'}};
  my $last_good_pos = $population_size*(1-$self->{'selection_rate'}) - 1;
  return @{$self->{'_population'}}[0..$last_good_pos];
}


=head2 compute_average_distance( $individual )

Computes the average hamming distance to the population 

=cut

sub compute_average_distance {
  my $self = shift;
  my $other = shift || croak "No other\n";
  my $distance;
  for my $p ( @{$self->{'_population'}} ) {
    $distance += hamming( $p->{'_str'}, $other->{'_str'} );
  }
  $distance /= @{$self->{'_population'}};
}

=head2 compute_min_distance( $individual )

Computes the average hamming distance to the population 

=cut

sub compute_min_distance {
  my $self = shift;
  my $other = shift || croak "No other\n";
  my $min_distance = length( $self->{'_population'}->[0]->{'_str'} );
  for my $p ( @{$self->{'_population'}} ) {
    my $this_distance = hamming( $p->{'_str'}, $other->{'_str'} );
    $min_distance = ( $this_distance < $min_distance )?$this_distance:$min_distance;
  }
  return $min_distance;

}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"Still there?";
