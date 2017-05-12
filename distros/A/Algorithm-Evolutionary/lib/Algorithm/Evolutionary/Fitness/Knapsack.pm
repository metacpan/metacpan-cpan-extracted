use strict; # -*- cperl -*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

    Algorithm::Evolutionary::Fitness::Knapsack - Fitness function for the knapsack problem

=head1 SYNOPSIS

    my $n_max=100;  #Max. number of elements to choose
    my $capacity=286; #Max. Capacity of the knapsack
    my $rho=5.0625; #Penalty coeficient
    my @profits = qw( 1..100 );
    my @weights = qw( 2.. 101 );

    my $knapsack = Algorithm::Evolutionary::Fitness::Knapsack->new( $n_max, $capacity, $rho, \@profits, \@weights ); 

=head1 DESCRIPTION

    Knapsack function with penalties applied in a particular way.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Fitness::Knapsack;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ / (\d+\.\d+)/ ) ;

use Carp qw( croak );
use base qw(Algorithm::Evolutionary::Fitness::String);

=head2 new

    Creates a new instance of the problem, with the said number of bits and peaks

=cut 

sub new {
  my $class = shift;
  my ( $n_max, $capacity, $rho, $profits_ref, $weights_ref ) = @_;

   if ( ((scalar @$profits_ref) != $n_max ) ||
	((scalar @$weights_ref) != $n_max ) ) {
     croak "Wrong number of profits";
   }

   if ( (scalar @$profits_ref) != ( scalar @$weights_ref ) ) {
     croak "Profits and weights differ";
   }

  #Instantiate superclass
  my $self = $class->SUPER::new();
  
  $self->{'capacity'} = $capacity;
  $self->{ 'rho' }  = $rho;
  $self->{ 'profits'} = $profits_ref;
  $self->{ 'weights'} = $weights_ref;

  $self->initialize();
  return $self;
}

sub _really_apply {
    my $self = shift;
    return  $self->knapsack( @_ );
}

=head2 knapsack

    Applies the knapsack problem to the string, using a penalty function

=cut

sub knapsack {
    my $self = shift;
    my $string = shift;

    my $cache = $self->{'_cache'};
    if ( $cache->{$string} ) {
	return $cache->{$string};
    }
    my $profit=0.0;
    my $weight=0.0;
    
    my @profits = @{$self->{'profits'}};
    my @weights = @{$self->{'weights'}};

    for (my $i=0 ; $i < length($string); $i++) {   #Compute weight
      my $this_bit=substr ($string, $i, 1);
      
      if ($this_bit == 1)  {
        $profit += $profits[$i];
        $weight += $weights[$i];
      }
    }
    
    if ($weight > $self->{'capacity'}) { # Apply penalty
      my $penalty = $self->{'rho'} * ($weight - $self->{'capacity'});
      $profit = $profit - ( $penalty + log(1.0 + $penalty) / log(2.0) );
    }

    #Y devolvemos la ganancia calculada
    $cache->{$string} = $profit;
    return $profit;
}


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/09/24 08:39:07 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Fitness/Knapsack.pm,v 3.1 2010/09/24 08:39:07 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut

"What???";
