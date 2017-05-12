use strict; #-*-cperl-*-
use warnings;

use lib qw( ../../.. );

=head1 NAME

Algorithm::Evolutionary::Op::Easy - evolutionary algorithm, single generation, with 
                    variable operators.
                 

=head1 SYNOPSIS

  my $easy_EA = new Algorithm::Evolutionary::Op::Easy $fitness_func;

  for ( my $i = 0; $i < $max_generations; $i++ ) {
    print "<", "="x 20, "Generation $i", "="x 20, ">\n"; 
    $easy_EA->apply(\@pop ); 
    for ( @pop ) { 
      print $_->asString, "\n"; 
    } 
  }

  #Define a default algorithm with predefined evaluation function,
  #Mutation and crossover. Default selection rate is 0.4
  my $algo = new Algorithm::Evolutionary::Op::Easy( $eval ); 

  #Define an easy single-generation algorithm with predefined mutation and crossover
  my $m = new Algorithm::Evolutionary::Op::Bitflip; #Changes a single bit
  my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover
  my $generation = new Algorithm::Evolutionary::Op::Easy( $rr, 0.2, [$m, $c] );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=cut

=head1 DESCRIPTION

"Easy" to use, single generation of an evolutionary algorithm. Takes
an arrayref of operators as input, or defines bitflip-mutation and
2-point crossover as default. The C<apply> method applies a single
iteration of the algorithm to the population it takes as input

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Easy;

our ($VERSION) = ( '$Revision: 3.5 $ ' =~ / (\d+\.\d+)/ ) ;

use Carp;

use Algorithm::Evolutionary::Wheel;
use Algorithm::Evolutionary::Op::Bitflip;
use Algorithm::Evolutionary::Op::Crossover;

use base 'Algorithm::Evolutionary::Op::Base';

# Class-wide constants
our $APPLIESTO =  'ARRAY';

=head2 new( $eval_func, [$operators_arrayref] )

Creates an algorithm that optimizes the handled fitness function and
reference to an array of operators. If this reference is null, an
array consisting of bitflip mutation and 2 point crossover is
generated. Which, of course, might not what you need in case you
don't have a binary chromosome.

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{_eval} = shift || croak "No eval function found";
  $self->{_selrate} = shift || 0.4;
  if ( @_ ) {
      $self->{_ops} = shift;
  } else {
      #Create mutation and crossover
      my $mutation = new Algorithm::Evolutionary::Op::Bitflip;
      push( @{$self->{_ops}}, $mutation );
      my $xover = new Algorithm::Evolutionary::Op::Crossover;
      push( @{$self->{_ops}}, $xover );
  }
  bless $self, $class;
  return $self;

}

=head2 set( $hashref, codehash, opshash )

Sets the instance variables. Takes a ref-to-hash (for options), codehash (for fitness) and opshash (for operators)

=cut

sub set {
  my $self = shift;
  my $hashref = shift || croak "No params here";
  my $codehash = shift || croak "No code here";
  my $opshash = shift || croak "No ops here";
  $self->{_selrate} = $hashref->{selrate};

  for ( keys %$codehash ) {
    $self->{"_$_"} =  eval "sub {  $codehash->{$_} } " || carp "Error compiling fitness function: $! => $@";
  }

  $self->{_ops} =();
  for ( keys %$opshash ) {
    #First element of the array contains the content, second the rate.
    push @{$self->{_ops}},  
      Algorithm::Evolutionary::Op::Base::fromXML( $_, $opshash->{$_}->[1], $opshash->{$_}->[0] );
  }
}

=head2 apply( $population )

Applies the algorithm to the population; checks that it receives a
ref-to-array as input, croaks if it does not. Returns a sorted,
culled, evaluated population for next generation.

=cut

sub apply ($) {
  my $self = shift;
  my $pop = shift || croak "No population here";

  #Evaluate
  my $eval = $self->{_eval};
  my @ops = @{$self->{_ops}};
  my @popEval;
  for ( @$pop ) {
    my $fitness;  #Evaluates only those that have no fitness
    if ( !defined ($_->Fitness() ) ) {
      $_->evaluate( $eval );
    }
    push @popEval, $_;
  }

  #Sort by fitness
  my @popsort = sort { $b->{_fitness} <=> $a->{_fitness}; }
    @popEval ;

  #Cull
  my $pringaos = int(($#popsort+1)*$self->{_selrate}); #+1 gives you size
  splice @popsort, -$pringaos;
 
  #Reproduce
  my @rates = map( $_->{'rate'}, @ops );
  my $opWheel = new Algorithm::Evolutionary::Wheel @rates;

  #Generate offpring;
  my $originalSize = $#popsort; # Just for random choice
  for ( my $i = 0; $i < $pringaos; $i ++ ) {
      my @offspring;
      my $selectedOp = $ops[ $opWheel->spin()];
      croak "Problems with selected operator" if !$selectedOp;
      for ( my $j = 0; $j < $selectedOp->arity(); $j ++ ) {
	my $chosen = $popsort[ int ( rand( $originalSize ) )];
	push( @offspring, $chosen ); #No need to clone, it's not changed in ops
      }
#     p rint "Op ", ref $selectedOp, "\n";
#      if ( (ref $selectedOp ) =~ /ssover/ ) {
#	print map( $_->{'_str'}."\n", @offspring );
#      }
      my $mutante = $selectedOp->apply( @offspring );
      croak "Error aplying operator" if !$mutante;
 #     print "Mutante ", $mutante->{'_str'}, "\n";
      push( @popsort, $mutante );
  }

  #Return
  @$pop = @popsort;
  
}

=head1 SEE ALSO

L<Algorithm::Evolutionary::Op::CanonicalGA>.
L<Algorithm::Evolutionary::Op::FullAlgorithm>.


=head1 Copyright
  
This file is released under the GPL. See the LICENSE file included in this distribution,
or go to http://www.fsf.org/licenses/gpl.txt


=cut

"The truth is out there";
