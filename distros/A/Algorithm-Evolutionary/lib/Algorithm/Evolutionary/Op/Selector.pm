use strict; #-*-cperl-*-
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Selector - Abstract base class for population selectors

=head1 SYNOPSIS

    package My::Selector;
    use base ' Algorithm::Evolutionary::Op::Selector';

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Abstract base class for population selectors; defines a few instance
    variables and interface elements

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Selector;
use Carp;

our ($VERSION) = ( '$Revision: 3.0 $ ' =~ / (\d+\.\d+)/ ) ;

use base 'Algorithm::Evolutionary::Op::Base';

=head2 new( $output_population_size )

Creates a new selector which outputs a fixed amount of
    individuals. This goes to the base class, since all selectors must
    know in advance how many they need to generate

=cut

sub new {
 my $class = shift;
 carp "Should be called from subclasses" if ( $class eq  __PACKAGE__ );
 my $self = {};
 $self->{_outputSize} = shift || croak "I need an output population size";
 bless $self, $class;
 return $self;
}

=head2 apply

Applies the tournament selection to a population, returning another of
the set size. This is an abstract method that should be implemented by
descendants. 

=cut

sub apply (@) {
    croak "To be redefined by siblings";
}

=head1 Known descendants


=over 4

=item * 

L<Algorithm::Evolutionary::Op::TournamentSelect>

=item * 

L<Algorithm::Evolutionary::Op::RouletteWheel>

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Selector.pm,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 

=cut

"C'mon Eileen";
