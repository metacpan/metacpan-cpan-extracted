use strict; #-*-CPerl-*- -*- hi-lock -*- 
use warnings;

use lib qw( ../../../lib );

=head1 NAME

Algorithm::Evolutionary::Experiment - Class for setting up an
experiment with algorithms and population 

=head1 SYNOPSIS
  
  use Algorithm::Evolutionary::Experiment;
  my $popSize = 20;
  my $indiType = 'BitString';
  my $indiSize = 64;
  
  #Algorithm might be anything of type Op
  my $ex = new Algorithm::Evolutionary::Experiment $popSize, $indiType, $indiSize, $algorithm; 


=head1 DESCRIPTION

This class contains (as instance variables) an algorithm and a population, and applies one to
the other.  Can be serialized
using XML, and can read an XML description of the experiment. 

=head1 METHODS

=cut

package Algorithm::Evolutionary::Experiment;

use Algorithm::Evolutionary::Utils qw(parse_xml);
use Algorithm::Evolutionary qw(Individual::Base
			       Op::Base
			       Op::Creator );

our $VERSION =   sprintf "3.4";

use Carp;

=head2 new( $pop_size, $type_of_individual, $individual_size )

Creates a new experiment. An C<Experiment> has two parts: the
   population and the algorithm. The population is created from a set
   of parameters: popSize, indiType and indiSize, and an array of
   algorithms that will be applied sequentially. Alternatively, if
   only operators are passed as an argument, it is understood as an
   array of algorithms (including, probably, initialization of the
   population).

=cut

sub new ($$$$;$) {
  my $class = shift;
  my $self = { _pop => [] };
  if ( index ( ref $_[0], 'Algorithm::Evolutionary') == -1 )   {  
    #If the first arg is not an algorithm, create one
    my $popSize = shift || carp "Pop size = 0, can't create\n";
    my $indiType = shift || carp "Empty individual class, can't create\n";
    my $indiSize = shift || carp "Empty individual size, no reasonable default, can't create\n";
    for ( my $i = 0; $i < $popSize; $i ++ ) {
      my $indi = Algorithm::Evolutionary::Individual::Base::new( $indiType, 
								 { length => $indiSize } );
      $indi->randomize();
      push @{$self->{_pop}}, $indi;
    }
  };
  @_ || croak "Can't find an algorithm";
  push @{$self->{_algo}}, @_;
  bless $self, $class;
  return $self
  
}

=head2 go

Applies the different operators in the order that they appear; returns the population
as a ref-to-array.

=cut

sub go {
  my $self = shift;
  for ( @{$self->{_algo}} ) {
	$_->apply( $self->{_pop} );
  }
  return $self->{_pop}
}

=head2 SEE ALSO

L<Algorithm::Evolutionary::Run> , another option for setting up
experiments, which is the one you should rather use, as XML support is
going to be deprecated (some day).

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"What???";
