use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Uniform_Crossover_Diff - Uniform crossover, but interchanges only those atoms that are different

                 

=head1 SYNOPSIS

  my $xmlStr3=<<EOC;
  <op name='Uniform_Crossover_Diff' type='binary' rate='1'>
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

  my $op4 = new Algorithm::Evolutionary::Op::Uniform_Crossover_Diff 1; #Uniform_Crossover_Diff with 1 crossover points

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Crossover operator for a GA acting only on those bits that are different.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Uniform_Crossover_Diff;

use lib qw( ../../.. );

our $VERSION =   sprintf "%d.1%02d", q$Revision: 3.6 $ =~ /(\d+)\.(\d+)/g; # Hack for avoiding version mismatch

use Carp;

use base 'Algorithm::Evolutionary::Op::Crossover';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::String';
our $ARITY = 2;

=head2 new( [$options_hash] [, $operation_priority] )

Creates a new n-point crossover operator, with 2 as the default number
of points, that is, the default would be
    my $options_hash = { crossover_rate => 0.5 };
    my $priority = 1;

=cut

sub new {
  my $class = shift;
  my $hash = { numPoints => shift || 1 };
  croak "Less than 1 points to cross" 
    if $hash->{'numPoints'} < 1;
  my $priority = shift || 1;
  my $self = Algorithm::Evolutionary::Op::Base::new( $class, $priority, $hash );
  return $self;
}

=head2 apply( $parent_1, $parent_2 )

Same as L<Algorithm::Evolutionary::Op::Uniform_Crossover>, but making
sure that what is interchanged is different.

=cut

sub  apply ($$){
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $arg2 =   shift || croak "No victim here!";
  my $victim2 = $arg2->clone();
  my $victim = $arg->clone();
  my $min_length = (  length( $victim->{_str} ) >  length( $victim2->{_str} ) )?
	 length( $victim2->{_str} ): length( $victim->{_str} );

  my @diffs;
  for ( my $i = 0; $i < $min_length; $i ++ ) {
    if  ( substr(  $victim2->{_str}, $i, 1 ) ne substr(  $victim->{_str}, $i, 1 ) ) {
      push @diffs, $i;
    }
  }

  for ( my $i = 0; $i < $self->{'_numPoints'}; $i ++ ) {
    if ( $#diffs > 0 ) {
      my $diff = splice( @diffs, rand(@diffs), 1 );
      substr( $victim->{'_str'}, $diff, 1 ) = substr( $victim2->{'_str'}, $diff, 1 );
    } else {
      last;
    }
  }
  $victim->Fitness( undef );
  return $victim; 
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2012/07/08 10:38:52 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Uniform_Crossover_Diff.pm,v 3.6 2012/07/08 10:38:52 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.6 $
  $Name $

=cut
