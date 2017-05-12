use strict; #-*-cperl-*-
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Storing - Applies the op and keeps the result

=head1 SYNOPSIS

  my %visited_population_hash;

  #Create from scratch with default operator rate
  my $op = new Algorithm::Evolutionary::Op::Bitflip 2; 

  my $stored_op = new Algorithm::Evolutionary::Op::Storing ( $op, \%visited_population_hash );

  
=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Applies an operator and stores the result in a hash (can be a tied
database), so that the whole population is stored. It creates an
operator whose results are cached, which could be useful for expensive
operators. 

=head1 METHODS 

=cut

package Algorithm::Evolutionary::Op::Storing;

use lib qw(../../..);

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.1 $ =~ /(\d+)\.(\d+)/g; # Hack for avoiding version mismatch

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

=head2 new( $operator, $population_hashref )

Wraps around the operator, and stores the reference to the population
hash that will be used

=cut

sub new {
  my $class = shift;
  my $op = shift || croak "No operator to wrap"; 
  my $pop_hash = shift || croak "No population hash";

  my $rate = $op->rate();
  my $self = Algorithm::Evolutionary::Op::Base::new( 'Algorithm::Evolutionary::Op::Storing', $rate);
  $self->{'_op'} = $op;
  $self->{'_pop_hash'} = $pop_hash;
  return $self;
}

=head2 apply( @victims )

Applies internal operator, and keeps result

=cut

sub apply ($;$){
  my $self = shift;
  my $result = $self->{'_op'}->apply( @_ );
  my $key = $result->as_string();
  if ( !$self->{'_pop_hash'}->{$key} ) {
    $self->{'_pop_hash'}->{$key} = $result;
  }
  return $self->{'_pop_hash'}->{$key};
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/02/14 06:55:36 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Storing.pm,v 3.1 2011/02/14 06:55:36 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut

