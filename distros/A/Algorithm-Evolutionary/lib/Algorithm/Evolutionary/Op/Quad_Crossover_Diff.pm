use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Quad_Crossover_Diff - Uniform crossover, but interchanges only those atoms that are different

                 

=head1 SYNOPSIS

  my $xmlStr3=<<EOC;
  <op name='Quad_Crossover_Diff' type='binary' rate='1'>
    <param name='numPoints' value='2' /> #Max is 2, anyways
  </op>
  EOC
  my $ref3 = XMLin($xmlStr3);

  my $op3 = Algorithm::Evolutionary::Op::Base->fromXML( $ref3 );
  print $op3->asXML(), "\n";

  my $indi = new Algorithm::Evolutionary::Individual::BitString 10;
  my $indi2 = $indi->clone();
  my $indi3 = $indi->clone(); #Operands are modified, so better to clone them
  $op3->apply( $indi2, $indi3 );

  my $op4 = new Algorithm::Evolutionary::Op::Quad_Crossover_Diff 1; #Quad_Crossover_Diff with 1 crossover points

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Crossover operator for a GA, takes args by reference and issues two
children from two parents

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Quad_Crossover_Diff;

use lib qw( ../../.. );

our $VERSION =   sprintf "%d.1%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/g; # Hack for avoiding version mismatch

use Carp;

use base 'Algorithm::Evolutionary::Op::Crossover';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::String';
our $ARITY = 2;

=head2 apply( $parent_1, $parent_2 )

Same as L<Algorithm::Evolutionary::Op::Crossover>, but changes
parents, does not return anything; that is, $parent_1 and $parent_2
interchange genetic material.

=cut

sub  apply ($$){
  my $self = shift;
  my $victim = shift || croak "No victim here!";
  my $victim2 = shift || croak "No victim here!";
#  croak "Incorrect type ".(ref $victim) if !$self->check($victim);
#  croak "Incorrect type ".(ref $victim2) if !$self->check($victim2);
  my $minlen = (  length( $victim->{_str} ) >  length( $victim2->{_str} ) )?
	 length( $victim2->{_str} ): length( $victim->{_str} );

  my @diffs;
  for ( my $i = 0; $i < $minlen; $i ++ ) {
    if  ( substr(  $victim2->{_str}, $i, 1 ) ne substr(  $victim->{_str}, $i, 1 ) ) {
      push @diffs, $i;
    }
  }

  for ( my $i = 0; $i < $self->{_numPoints}; $i ++ ) {
    if ( @diffs ) {
      my $diff = splice( @diffs, rand(@diffs), 1 );
      my $char = substr($victim->{'_str'},$diff,1);
      substr( $victim->{_str}, $diff, 1 ) = substr( $victim2->{_str}, $diff, 1 );
      substr( $victim2->{_str}, $diff, 1 ) = $char;
    } else {
      last;
    }
  }
#  print "Puntos: $pt1, $range \n";
  $victim->Fitness( undef );
  $victim2->Fitness( undef );
  return undef; #As a warning that you should not expect anything
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/12/08 17:34:22 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Quad_Crossover_Diff.pm,v 1.2 2010/12/08 17:34:22 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.2 $
  $Name $

=cut
