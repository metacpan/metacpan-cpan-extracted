use strict; # -*- cperl -*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Fitness::ONEMAX - Fitness function for the ONEMAX or count-ones problem

=head1 SYNOPSIS

    my $onemax =  new Algorithm::Evolutionary::Fitness::Knapsack;
    my $string = "1010101010101010";
    print $onemax->apply($string);

=head1 DESCRIPTION

ONEMAX is the classical count-ones optimization function. Fast to implement, and good for early prototyping of new evolutionary algorithms.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Fitness::ONEMAX;

our ($VERSION) = ( '$Revision: 3.0 $ ' =~ / (\d+\.\d+)/ ) ;

use Carp qw( croak );
use base qw(Algorithm::Evolutionary::Fitness::String);


sub _really_apply {
    my $self = shift;
    return  $self->onemax( @_ );
}

=head2 onemax

Computes the number of ones, using base class cache

=cut

sub onemax {
    my $self = shift;
    my $string = shift;

    my $cache = $self->{'_cache'};
    if ( defined $cache->{$string} ) {
	return $cache->{$string};
    }
    my $num_ones = ($string =~ tr/1/1/);
#    my $num_ones = grep( $_, split(//, $string ));
#     while ( $string ) {
#       $num_ones += chop( $string );
#     }
    $cache->{$string} = $num_ones;
    return $num_ones;
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Fitness/ONEMAX.pm,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.0 $

=cut

"What???";
