package Algorithm::MasterMind::Evo;

use warnings;
use strict;
use Carp;

use lib qw(../../lib ../../../../Algorithm-Evolutionary/lib/ 
	   ../../Algorithm-Evolutionary/lib/
	   ../../../lib);

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/g; 

use base 'Algorithm::MasterMind::Evolutionary_Base';
use Algorithm::MasterMind qw(partitions);

use Algorithm::Evolutionary qw(Op::String_Mutation
			       Op::Permutation
			       Op::Uniform_Crossover_Diff
			       Op::Breeder_Diverser
			       Op::Replace_Different
			       Op::Tournament_Selection
			       Individual::String );

use Algorithm::Combinatorics qw(permutations);
use Algorithm::MasterMind::Partition::Most;
use Clone qw(clone);

# ---------------------------------------------------------------------------
use constant { MAX_CONSISTENT_SET => 20, # This number 20 was computed in NICSO paper, valid for default 4-6 mastermind
	       MAX_GENERATIONS_RESET => 100,
	       MAX_GENERATIONS_EQUAL => 3} ;

sub factorial {
  my $value = shift;
  my $factorial = 1;
  $factorial *= $_ foreach 1..$value;
  return $factorial;
}


sub initialize {
  my $self = shift;
  my $options = shift;
  for my $o ( keys %$options ) {
    $self->{"_$o"} = clone($options->{$o});
  }
  croak "No population" if $self->{'_pop_size'} == 0;

  # Variation operators
  my $mutation_rate = $options->{'mutation_rate'} || 1;
  my $permutation_rate = $options->{'permutation_rate'} || 0;
  my $permutation_iters = $options->{'permutation_iterations'} || factorial($options->{'length'}) - 1 ;
  my $xover_rate = $options->{'xover_rate'} || 1;
  my $max_number_of_consistent = $options->{'consistent_set_card'} 
    || MAX_CONSISTENT_SET;  
  $self->{'_replacement_rate'}= $self->{'_replacement_rate'} || 0.25;
  my $m = new Algorithm::Evolutionary::Op::String_Mutation $mutation_rate ; # Rate = 1
  my $c = Algorithm::Evolutionary::Op::Uniform_Crossover_Diff->new( $options->{'length'}/2, $xover_rate ); 
  my $operators = [$m,$c];
  if ( $permutation_rate > 0 ) {
    my $p =  new Algorithm::Evolutionary::Op::Permutation $permutation_rate, $permutation_iters; 
    push @$operators, $p;
  }
  my $select = new Algorithm::Evolutionary::Op::Tournament_Selection $self->{'_tournament_size'} || 2;
  if (! $self->{'_ga'} ) { # Not given as an option
    $self->{'_ga'} = new Algorithm::Evolutionary::Op::Breeder_Diverser( $operators, $select );    
  }
  $self->{'_replacer'} = new Algorithm::Evolutionary::Op::Replace_Different;

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
#----------------------------------------------------------------------------
sub eliminate_last_played {
  my $self = shift;
  my $last_played = $self->{'_last'};

  for my $p ( @{$self->{'_pop'}} ) {
    if ($p->{'_str'} eq $last_played ) {
      $p =  new Algorithm::Evolutionary::Individual::String( $self->{'_alphabet'}, $self->{'_length'} );
    }
  }
}


#----------------------------------------------------------------------------

sub issue_next {
  my $self = shift;
  my @rules =  @{$self->{'_rules'}};
  my @alphabet = @{$self->{'_alphabet'}};
  my $length = $self->{'_length'};
  my $pop = $self->{'_pop'};
  my $rules =  $self->number_of_rules();
  my $ga = $self->{'_ga'};
  my $max_number_of_consistent  = $self->{'_max_consistent'};

  my $last_rule = $rules[$#rules];
  my $alphabet_size = @{$self->{'_alphabet'}};

  if ( $self->{'_played_out'} ) {
    $self->eliminate_last_played;
  }
  #Check for combination guessed right except for permutation
  if ($last_rule->{'blacks'}+$last_rule->{'whites'} == $length ) {
    if ( ! $self->{'_consistent_endgame'} ) {
      my %permutations;
      map( $permutations{$_} = 1,
	   map(join("",@$_), 
	       permutations([ split( //, $last_rule->{'combination'} ) ] ) ) );
      my @permutations = keys %permutations;
      $self->{'_endgame'}  = 
	Algorithm::MasterMind::Partition::Most->start_from( { evaluated => $self->{'_evaluated'},
							      alphabet => \@alphabet,
							      rules => $self->{'_rules'},
							      consistent => \@permutations} );
    } else {
      $self->{'_endgame'}  = 
	Algorithm::MasterMind::Partition::Most->start_from( { evaluated => $self->{'_evaluated'},
							      alphabet => \@alphabet,
							      rules => $self->{'_rules'},
							      consistent => $self->{'_consistent_endgame'} } );
    }
    my $string =  $self->{'_endgame'}->issue_next();
    $self->{'_consistent_endgame'} =  $self->{'_endgame'}->{'_consistent'};
    $self->{'_evaluated'} = $self->{'_endgame'}->{'_evaluated'};
    return  $self->{'_last'} = $string;
  } else {
    #Check for no pegs
    if ($last_rule->{'blacks'}+$last_rule->{'whites'} == 0 ) {
      my %these_colors;
      map ( $these_colors{$_} = 1, split( //, $last_rule->{'combination'} ) );
      for (my $i = 0; $i < @{$self->{'_alphabet'}}; $i++ ) {
	if ($these_colors{$self->{'_alphabet'}->[$i]} ) {
	  delete $self->{'_alphabet'}->[$i]  ;
	}
      }
      @{$self->{'_alphabet'}} = grep( $_,  @{$self->{'_alphabet'}} ); # Eliminate nulls
      if ( @{$self->{'_alphabet'}} == 1 ) { # It could happen, and has happened
	  return $self->{'_alphabet'}->[0] x $length;
      }
      if ( @{$self->{'_alphabet'}} < $alphabet_size ) {
	  $self->realphabet;
	  if ( !$self->{'_noshrink'} ) {
	    my $shrinkage =  @{$self->{'_alphabet'}} /$alphabet_size;
	    print "Shrinking to size ", @$pop * $shrinkage
	      ," with alphabet ", join( " ", @{$self->{'_alphabet'}} ), "\n";
	    $self->shrink_to( (scalar @$pop) * $shrinkage );
	  }
	}
      
    }

    #Recalculate distances, new turn
    my (%consistent );
    my $partitions;
    my $distance = $self->{'_distance'};
#    print "Evaluating all \n";
    for my $p ( @$pop ) {
	($p->{'_distance'}, $p->{'_matches'}) = @{$self->$distance( $p->{'_str'} )};
#      ($p->{'_distance'}, $p->{'_matches'}) = @{$self->distance( $p )};
#	print "$p->{'_distance'}, $p->{'_matches'}) =  $p->{'_str'} \n";
	if ($p->{'_matches'} == $rules) {
	  push @{$consistent{$p->{'_str'}}}, $p;
	} else {
	  $p->{'_partitions'} = 0;
	}
    }
    
    my $number_of_consistent = keys %consistent;
    if ( $number_of_consistent > 1 ) {
      $partitions = partitions( keys %consistent );
      # Need this to compute fitness
      for my $c ( keys %$partitions ) {
	for my $p ( @{$consistent{$c}} ) {
	  $p->{'_partitions'} = scalar (keys  %{$partitions->{$c}});
	}
      }
    } elsif ( $number_of_consistent == 1 ) {
      for my $c ( keys %consistent ) {
	for my $p ( @{$consistent{$c}} ) {
	  $p->{'_partitions'} = 1;
	}
      }
    }
    my $generations_equal = 0;
    my $this_number_of_consistent = $number_of_consistent;

    while ( $this_number_of_consistent < $max_number_of_consistent ) {  

      compute_fitness( $pop ); 
      my $new_pop = $ga->apply( $pop, @$pop * $self->{'_replacement_rate'} );  #Apply GA
      for my $p ( @$new_pop ) {
	($p->{'_distance'}, $p->{'_matches'}) = @{$self->$distance( $p->{'_str'} )};
	if ($p->{'_matches'} == $rules) {
	  push @{$consistent{$p->{'_str'}}}, $p;
	} else {
	  $p->{'_partitions'} = 0;
	}
      }
      $pop = $self->{'_replacer'}->apply( $pop, $new_pop );
      $this_number_of_consistent =  keys %consistent;
      if ( $this_number_of_consistent == $number_of_consistent ) {
	$generations_equal++;
      } else {
	$generations_equal = 0;
	$number_of_consistent = $this_number_of_consistent;
	# Compute number of partitions
	if ( $number_of_consistent > 1 ) {
	  $partitions = partitions( keys %consistent );
	} else {
	  $partitions->{(keys %consistent )[0]} = { "allblacks" => 1}; # I know, this is a hack
	}
      }
      for my $c ( keys %consistent ) {
	for my $p ( @{$consistent{$c}}) {
	  $p->{'_partitions'} = scalar (keys  %{$partitions->{$c}});
	}
      }

      if ($generations_equal == MAX_GENERATIONS_RESET ) { #reset pop
	# Print for debugging
	my %population;
	for my $p ( @$pop ) {
	  $population{$p->{'_str'}}++;
	}
	for my $s ( sort { $population{$b} <=> $population{$a} } keys %population ) {
	  print $s, ": ", $population{$s}, " C\n";
	}
	print "Reset\n\n";
	#Do the thing
	$ga->reset( $pop );
	for my $p ( @$pop ) {
	  ($p->{'_distance'}, $p->{'_matches'}) = @{$self->$distance( $p->{'_str'} )};
	}
	$generations_equal = 0;
      }
      last if ( $generations_equal >= MAX_GENERATIONS_EQUAL ) 
	&& ( $this_number_of_consistent >= 1 ) ;
    } # end while
    
    $self->{'_consistent'} = \%consistent; #This mainly for outside info
    if ( $this_number_of_consistent > 1 ) {
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
}

"some blacks, 1 white"; # Magic true value required at end of module

__END__

=head1 NAME

Algorithm::MasterMind::Evo -  New evolutionary algorithms solving MM - Evo* version


=head1 SYNOPSIS

    use Algorithm::MasterMind::Evo;

  
=head1 DESCRIPTION

This algorithm is a new evolutionary algorithm that includes EndGames
and also using Most Parts score for evolving solutions to
Mastermind. I was introduced in "Improving and Scaling Evolutionary
Approaches to the MasterMind Problem", by Merelo, Cotta and Mora which we
expect you will cite if you include this in your work.

=head1 INTERFACE

=head2 factorial

Computes factorial, needed as a default value for the permutation operator 

=head2 initialize

Initializes the genetic part of the algorithm

=head2 issue_next()

Issues the next combination, using this method.

=head2 compute_fitness()

Processes "raw" fitness to assign fitness once consistency and/or
distance to it is known. It's lineally scaled to make the lowes
combination = 1

=head2 eliminate_last_played()

Eliminates the last string played to avoid having problems in the
population, and substitute it for a random one. 

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, 2012 JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

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
