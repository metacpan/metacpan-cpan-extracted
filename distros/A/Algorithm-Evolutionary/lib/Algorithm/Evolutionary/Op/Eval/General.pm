use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Eval::General - General and simple population evaluator
                 
=head1 SYNOPSIS

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

A general evaluator: applies an evaluation function to each member of
the population 

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Eval::General;

use lib qw(../../..);

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.0 $ =~ /(\d+)\.(\d+)/g; 

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

# Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( $evaluation_function )

Creates an algorithm, with no defaults except for the default
replacement operator (defaults to L<Algorithm::Evolutionary::Op::ReplaceWorst>)

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{_eval} = shift || croak "No eval function found";
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

Evaluates the population, setting its fitness value

=cut

sub apply ($) {
    my $self = shift;
    my $pop = shift || croak "No population here";
    croak "Incorrect type ".(ref $pop) if  ref( $pop ) ne $APPLIESTO;

    #Evaluate only the new ones
    my $eval = $self->{_eval};
    #Eliminate and substitute
    map( defined $_->Fitness() || $_->evaluate( $eval), @$pop );
    
}

=head1 SEE ALSO

=over 4

=item * 

L<Algorithm::Evolutionary::Fitness::Base>

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Eval/General.pm,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.0 $

=cut

"The truth is out there";
