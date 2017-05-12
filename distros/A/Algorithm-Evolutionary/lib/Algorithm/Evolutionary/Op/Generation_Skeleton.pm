use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Generation_Skeleton - Even more customizable single generation for an evolutionary algorithm.
                 
=head1 SYNOPSIS

    use Algorithm::Evolutionary qw( Individual::BitString 
				Op::Mutation Op::Crossover
				Op::RouletteWheel
				Fitness::ONEMAX Op::Generation_Skeleton
				Op::Replace_Worst);

    use Algorithm::Evolutionary::Utils qw(average);

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

    my @sortPop = sort { $b->Fitness() <=> $a->Fitness() } @pop;
    my $bestIndi = $sortPop[0];
    my $previous_average = average( \@sortPop );
    $generation->apply( \@sortPop );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Skeleton class for a general single-generation (or single step) in an
evolutionary algorithm; its instantiation requires a
L<fitness|Algorithm::Evolutionary::Fitness::Base> function, a
L<Selector|Algorithm::Evolutionary::Op::Selector>, a reference to an
array of operators and a replacement operator

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Generation_Skeleton;

use lib qw(../../..);

our $VERSION = '3.3';

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

use Algorithm::Evolutionary qw(Wheel Op::Replace_Worst);
use Sort::Key qw( rnkeysort);

# Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( $evaluation_function, $selector, $ref_to_operator_array, $replacement_operator )

Creates an algorithm, with no defaults except for the default
replacement operator (defaults to L<Algorithm::Evolutionary::Op::ReplaceWorst>)

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{_eval} = shift || croak "No eval function found";
  $self->{_selector} = shift || croak "No selector found";
  $self->{_ops} = shift || croak "No operators found";
  $self->{_replacementRate} = shift || 1; #Default to all  replaced
  $self->{_replacement_op} = shift || new Algorithm::Evolutionary::Op::Replace_Worst;
  bless $self, $class;
  return $self;
}


=head2 set( $ref_to_params_hash, $ref_to_code_hash, $ref_to_operators_hash )

Sets the instance variables. Takes a ref-to-hash as
input. Not intended to be used from outside the class

=cut

sub set {
  my $self = shift;
  my $hashref = shift || croak "No params here";
  my $codehash = shift || croak "No code here";
  my $opshash = shift || croak "No ops here";

  for ( keys %$codehash ) {
	$self->{"_$_"} =  eval "sub { $codehash->{$_} } ";
  }

  $self->{_ops} =();
  for ( keys %$opshash ) {
    push @{$self->{_ops}}, 
      Algorithm::Evolutionary::Op::Base::fromXML( $_, $opshash->{$_}->[1], $opshash->{$_}->[0] ) ;
  }
}

=head2 apply( $population )

Applies the algorithm to the population, which should have
been evaluated first; checks that it receives a
ref-to-array as input, croaks if it does not. Returns a sorted,
culled, evaluated population for next generation.

=cut

sub apply ($) {
    my $self = shift;
    my $pop = shift || croak "No population here";
    croak "Incorrect type ".(ref $pop) if  ref( $pop ) ne $APPLIESTO;

    #Breed
    my $selector = $self->{'_selector'};
    my @genitors = $selector->apply( @$pop );

    #Reproduce
    my $totRate = 0;
    my @rates;
    my @ops = @{$self->{'_ops'}};
    for ( @ops ) {
	push( @rates, $_->{'rate'});
    }
    my $opWheel = new Algorithm::Evolutionary::Wheel @rates;

    my @newpop;
    my $pringaos =  @$pop  * $self->{'_replacementRate'} ;
    for ( my $i = 0; $i < $pringaos; $i++ ) {
	my @offspring;
	my $selectedOp = $ops[ $opWheel->spin()];
#	  print $selectedOp->asXML;
	for ( my $j = 0; $j < $selectedOp->arity(); $j ++ ) {
	    my $chosen = $genitors[ rand( @genitors )];
#		print "Elegido ", $chosen->asString(), "\n";
	    push( @offspring, $chosen->clone() );
	}
	my $mutante = $selectedOp->apply( @offspring );
	push( @newpop, $mutante );
    }
    
    my $eval = $self->{'_eval'};
    map( $_->evaluate( $eval), @newpop );

    #Eliminate and substitute
    my $pop_hash = $self->{'_replacement_op'}->apply( $pop, \@newpop );
    @$pop = rnkeysort { $_->{'_fitness'} } @$pop_hash ;    
}

=head1 SEE ALSO

More or less in the same ballpark, alternatives to this one

=over 4

=item * 

L<Algorithm::Evolutionary::Op::GeneralGeneration>

=back

=head1 Copyright
  
This file is released under the GPL. See the LICENSE file included in this distribution,
or go to http://www.fsf.org/licenses/gpl.txt

=cut

"The truth is out there";
