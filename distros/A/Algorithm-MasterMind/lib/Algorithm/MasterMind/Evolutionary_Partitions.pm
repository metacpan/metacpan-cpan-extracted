package Algorithm::MasterMind::Evolutionary_Partitions;

use warnings;
use strict;
use Carp;

use lib qw(../../lib ../../../../Algorithm-Evolutionary/lib/ 
	   ../../Algorithm-Evolutionary/lib/
	   ../../../lib);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::MasterMind::Evolutionary';

use Algorithm::MasterMind qw(partitions);

use Algorithm::Evolutionary::Op::String_Mutation; 
use Algorithm::Evolutionary::Op::Permutation; 
use Algorithm::Evolutionary::Op::Crossover;
use Algorithm::Evolutionary::Op::Easy;
use Algorithm::Evolutionary::Individual::String;

# ---------------------------------------------------------------------------


sub issue_next {
  my $self = shift;
  my $rules =  $self->number_of_rules();
  my @alphabet = @{$self->{'_alphabet'}};
  my $length = $self->{'_length'};
  my $pop = $self->{'_pop'};
  my $ga = $self->{'_ga'};
  map( $_->evaluate( $self->{'_fitness'}), @$pop );
  my @ranked_pop = sort { $b->{_fitness} <=> $a->{_fitness}; } @$pop;

  my %consistent;
#   print "Consistent in ", scalar keys %{$self->{'_consistent'}}, "\n";
  if (  $self->{'_consistent'} ) { #Check for consistency
    %consistent = %{$self->{'_consistent'}};
    for my $c (keys %consistent ) {
      my $match = $self->matches( $c );
      if ( $match->{'matches'} < $rules ) {
	delete $consistent{$c};
      }
    }
  } else {
    %consistent = ();
  }
#  print "Consistent out ", scalar keys %consistent, "\n";
  
  while ( $ranked_pop[0]->{'_matches'} == $rules ) {
    $consistent{$ranked_pop[0]->{'_str'}} = $ranked_pop[0];
    shift @ranked_pop;
  }
  my $generations_equal = 0;
  # The 20 was computed in NICSO paper, valid for normal mastermind
  my $number_of_consistent = keys %consistent;
  
#  print "Consistent new ", scalar keys %consistent, "\n";
  while (  $number_of_consistent < 20 ) {
    my $this_number_of_consistent = $number_of_consistent;
    $ga->apply( $pop );
    for my $p( @$pop ) { 
      my $matches = $self->matches( $p->{'_str'} );
#      print "* ", $p->{'_str'}, " ", $matches->{'matches'}, "\n";      
      if ( $matches->{'matches'} == $rules ) {
#	print "Combination  ", $p->{'_str'}, " matches ", $p->{'_matches'}, "\n";
	$consistent{$p->{'_str'}} = $p;
      }
    } 
    $number_of_consistent = keys %consistent;
    if ( $this_number_of_consistent == $number_of_consistent ) {
      $generations_equal++;
    } else {
      $generations_equal = 0;
    }

    if ($generations_equal == 15 ) {
      $ga->reset( $pop );
      $generations_equal = 0;
    }

#    print "G $generations_equal $number_of_consistent \n";
    last if ( ( $generations_equal >= 3 ) && ( $number_of_consistent >= 1 ) );
  }

#  print "After GA combinations ", join( " ", keys %consistent ), "\n";
  $self->{'_consistent'} = \%consistent;
  if ( $number_of_consistent > 1 ) {
#    print "Consistent ", scalar keys %consistent, "\n";
    #Use whatever we've got to compute number of partitions
    my $partitions = partitions( keys %consistent );
    
    my $max_partitions = 0;
    my %max_c;
    for my $c ( keys %$partitions ) {
      my $this_max =  keys %{$partitions->{$c}};
      $max_c{$c} = $this_max;
      if ( $this_max > $max_partitions ) {
	$max_partitions = $this_max;
      }
    }
    # Find all partitions with that max
    my @max_c = grep( $max_c{$_} == $max_partitions, keys %max_c );
    # Break ties
    my $string = $max_c[ rand( @max_c )];
    # Obtain next
    return  $self->{'_last'} = $string;
  } else {
    return $self->{'_last'} = (keys %consistent)[0];
  }
  
}

"some blacks, 0 white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Evolutionary_Partitions - Evolutionary algorithm with the partition method


=head1 SYNOPSIS

    use Algorithm::MasterMind::Evolutionary_Partitions;

  
=head1 DESCRIPTION

The partition method was introduced in a 2009 paper, and then changed
by Runarsson and Merelo. 

=head1 INTERFACE 

=head2 issue_next()

Issues the next combination

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
