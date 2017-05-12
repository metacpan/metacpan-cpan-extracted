use strict; #-*-cperl-*-
use warnings;

use lib qw( ../../.. );

=head1 NAME

Algorithm::Evolutionary::Op::Replace_Different - Incorporate
individuals into the population replacing the worst ones but only if
they are different.

=head1 SYNOPSIS

  my $op = new Algorithm::Evolutionary::Op::Replace_Different; 
  $op->apply( $old_population_hashref, $new_population_hashref );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Replaces only unique individuals, avoiding to introduce copies of them
into the new population .

=head1 METHODS 

=cut

package Algorithm::Evolutionary::Op::Replace_Different;

our $VERSION =   sprintf "%d.%d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/g; 

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

use Sort::Key qw(nkeysort);

#Class-wide constants
our $ARITY = 1;

=head2 apply( $population, $chromosome_list )

    Eliminates the worst individuals in the population, replacing them
    by the list of new chromosomes, but only if they are different to the ones already present. The population must be evaluated,
    but there's no need to have it sorted in advance.  It returns a
    sorted population.

=cut

sub apply ($;$){
  my $self = shift;
  my $population = shift || croak "No population here!";
  my $chromosome_list = shift || croak "No new population here!";
  
  #Sort
  my @sorted_population = nkeysort { $_->Fitness() } @$population ;

  my %population_hash;
  map( $population_hash{$_->{'_str'}} = 1, @sorted_population );

  my @non_repeated = grep( !$population_hash{$_->{'_str'}}, @$chromosome_list );
  my $to_eliminate = scalar @non_repeated;
  if ( $to_eliminate > 0 ) {
    # print "Eliminating $to_eliminate\n";
    splice ( @sorted_population, 0,  $to_eliminate );
    push @sorted_population, @non_repeated;
  }
  return \@sorted_population;

}

=head1 SEE ALSO

L<Algorithm::Evolutionary::Op::Generation_Skeleton>, where the
replacement policy is one of the parameters. 

It can also be used in L<POE::Component::Algorithm::Evolutionary> for
insertion of new individuals asynchronously.

Another breeder is L<Algorithm::Evolutionary::Op::Replace_Worst>.

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2013/01/05 12:43:32 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Replace_Different.pm,v 1.3 2013/01/05 12:43:32 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.3 $
  $Name $

=cut

