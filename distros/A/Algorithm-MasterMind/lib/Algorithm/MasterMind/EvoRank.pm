package Algorithm::MasterMind::EvoRank;

use warnings;
use strict;
use Carp;

use lib qw(../../lib ../../../../Algorithm-Evolutionary/lib/ 
	   ../../Algorithm-Evolutionary/lib/
	   ../../../lib);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::MasterMind::Evolutionary_Base';

use Algorithm::MasterMind qw(partitions);

use Algorithm::Evolutionary qw(Op::QuadXOver
			       Op::String_Mutation
			       Op::Permutation
			       Op::Crossover
			       Op::Canonical_GA_NN
			       Individual::String );

use Clone::Fast qw(clone);

# ---------------------------------------------------------------------------
use constant { MAX_CONSISTENT_SET => 20, # This number 20 was computed in NICSO paper, valid for default 4-6 mastermind
	       MAX_GENERATIONS_RESET => 50,
	       MAX_GENERATIONS_EQUAL => 3} ;

sub initialize {
  my $self = shift;
  my $options = shift;
  for my $o ( keys %$options ) {
    $self->{"_$o"} = clone($options->{$o});
  }
  croak "No population" if $self->{'_pop_size'} == 0;
  # Variation operators
  my $mutation_rate = $options->{'mutation_rate'} || 1;
  my $xover_rate = $options->{'xover_rate'} || 2;
  my $permutation_rate = $options->{'permutation_rate'} || 0;
  my $max_number_of_consistent = $options->{'consistent_set_card'} || MAX_CONSISTENT_SET;   
  my $m = new Algorithm::Evolutionary::Op::String_Mutation $mutation_rate ; # Rate = 1
  my $c = Algorithm::Evolutionary::Op::QuadXOver->new( 1, $xover_rate ); 
  my $operators = [$m,$c];
  if ( $permutation_rate > 0 ) {
    my $p =  new Algorithm::Evolutionary::Op::Permutation $permutation_rate; 
    push @$operators, $p;
  }
  if (! $self->{'_ga'} ) { # Not given as an option
    $self->{'_ga'} = new Algorithm::Evolutionary::Op::Canonical_GA_NN( $options->{'replacement_rate'},
								       $operators );    
  }

  if (!$self->{'_distance'}) {
    $self->{'_distance'} = 'distance_taxicab';
  }
  $self->{'_max_consistent'} = $max_number_of_consistent;
}

sub compute_fitness {
  my $pop = shift;
  #Compute min
  my $min_distance = 0;
  for my $p ( @$pop ) {
    $min_distance = ( $p->{'_distance'} < $min_distance )?
      $p->{'_distance'}:
	$min_distance;
  }

  for my $p ( @$pop ) {
    $p->Fitness( $p->{'_distance'}+
		 ($p->{'_partitions'}?$p->{'_partitions'}:0)-
		 $min_distance + 1);
  }
}

sub issue_next {
  my $self = shift;
  my $rules =  $self->number_of_rules();
  my @alphabet = @{$self->{'_alphabet'}};
  my $length = $self->{'_length'};
  my $pop = $self->{'_pop'};
  my $ga = $self->{'_ga'};
  my $max_number_of_consistent  = $self->{'_max_consistent'};

  #Recalculate distances, new game
  my (%consistent );
  my $partitions;
  my $distance = $self->{'_distance'};
  for my $p ( @$pop ) {
      ($p->{'_distance'}, $p->{'_matches'}) = @{$self->$distance( $p->{'_str'} )};
#      ($p->{'_distance'}, $p->{'_matches'}) = @{$self->distance( $p )};
      $consistent{$p->{'_str'}} = $p if ($p->{'_matches'} == $rules);
  }

  my $number_of_consistent = keys %consistent;
  if ( $number_of_consistent > 1 ) {
    $partitions = partitions( keys %consistent );      
    for my $c ( keys %$partitions ) {
      $consistent{$c}->{'_partitions'} = scalar (keys  %{$partitions->{$c}});
    }
  }
  my $generations_equal = 0;
  my $this_number_of_consistent = $number_of_consistent;
  
  while ( $this_number_of_consistent < $max_number_of_consistent ) {  
     
    #Compute fitness
    compute_fitness( $pop );
    #      print join( " - ", map( $_->{'_fitness'}, @$pop )), "\n";
    
    #Apply GA
    $ga->apply( $pop );
    
    #Compute new distances
    %consistent = ();  # Empty to avoid problems
    for my $p ( @$pop ) {
      ($p->{'_distance'}, $p->{'_matches'}) = @{$self->$distance( $p->{'_str'} )};
#	($p->{'_distance'}, $p->{'_matches'}) = @{$self->distance( $p )};
	if ($p->{'_matches'} == $rules) {
	    $consistent{$p->{'_str'}} = $p;
	    #	print $p->{'_str'}, " -> ", $p->{'_distance'}, " - ";
	} else {
	    $p->{'_partitions'} = 0;
	}
    }
    
    #Check termination again, and reset
    if ($generations_equal == MAX_GENERATIONS_RESET ) {
	$ga->reset( $pop );
	for my $p ( @$pop ) {
	($p->{'_distance'}, $p->{'_matches'}) = @{$self->$distance( $p->{'_str'} )};
#	    ($p->{'_distance'}, $p->{'_matches'}) = @{$self->distance( $p )};
	}
	$generations_equal = 0;
    }

    #Check termination conditions
    $this_number_of_consistent =  keys %consistent;
    if ( $this_number_of_consistent == $number_of_consistent ) {
      $generations_equal++;
    } else {
      $generations_equal = 0;
      $number_of_consistent = $this_number_of_consistent;
      # Compute number of partitions
      if ( $number_of_consistent > 1 ) {
	$partitions = partitions( keys %consistent );      
	for my $c ( keys %$partitions ) {
	  $consistent{$c}->{'_partitions'} = scalar (keys  %{$partitions->{$c}});
	}
      }
    }
    last if ( $generations_equal >= MAX_GENERATIONS_EQUAL ) && ( $this_number_of_consistent >= 1 ) ;
    #    print "G $generations_equal $this_number_of_consistent \n";
  }
  
  $self->{'_consistent'} = \%consistent; #This mainly for outside info
  #  print "After GA combinations ", join( " ", keys %consistent ), "\n";
#  print "Consistent + => ", join( "-", sort keys %consistent ), "\n\n"; 
  if ( $this_number_of_consistent > 1 ) {
    #    print "Consistent ", scalar keys %consistent, "\n";
    #Use whatever we've got to compute number of partitions
#    my $partitions = partitions( keys %consistent );
    
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

Algorithm::MasterMind::EvoRank - Evolutionary algorithm with the
partition method and ranked fitness, prepared for GECCO 2010 


=head1 SYNOPSIS

    use Algorithm::MasterMind::Evolutionary_Partitions;

  
=head1 DESCRIPTION

The partition method was introduced in a 2010 paper, and then changed
by Runarsson and Merelo to incorporate it in the genetic search. It
was prepared for a conference paper, this one:

  @INPROCEEDINGS{mm:cig,
   author={Merelo, J.J. and Mora, A.M. and Runarsson, T.P. and Cotta, C.},
   booktitle={Computational Intelligence and Games (CIG), 2010 IEEE Symposium on}, 
   title={Assessing efficiency of different evolutionary strategies playing MasterMind},
   year=2010,
   month={August},
   pages={38--45},
   keywords={MasterMind player;constrained optimization problem;evolutionary algorithm;evolutionary strategy;fitness function;computer games;evolutionary computation;},
   doi={10.1109/ITW.2010.5593373}
  }

This method is the evolutionary equivalent of
L<Algorithm::MasterMind::Partitition::Most>, using the number of
non-null partitions to score consistent combinations, while using
distance-to-consistency to score non-consistent. 

=head1 INTERFACE 

=head2 initialize

Initializes the genetic part of the algorithm

=head2 issue_next()

Issues the next combination, using this method. Every generation runs
an evolutionary algorithm to compute the next string.

=head2 compute_fitness()

Processes "raw" fitness to assign fitness once consistency and/or
distance to it is known. It's lineally scaled to make the lowest
combination have a fitness equal to 1, which is needed just in case
the selection method uses roulette wheel (which it does).

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, 2010 JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

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
