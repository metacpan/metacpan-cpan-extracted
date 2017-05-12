package Algorithm::Evolutionary::Simple;

use warnings;
use strict;
use Carp qw(croak);

our $VERSION = '0.2'; # Probably such an increase is not guaranteed, but...

use base 'Exporter';
use Sort::Key::Top qw(rnkeytop) ;

our @EXPORT_OK= qw( random_chromosome max_ones max_ones_fast spin 
		    get_pool_roulette_wheel get_pool_binary_tournament
		    produce_offspring mutate crossover single_generation );

# Module implementation here
sub random_chromosome {
  my $length = shift;
  my $string = '';
  for (1..$length) {
    $string .= (rand >0.5)?1:0;
  }
  $string;
}

sub max_ones {
  my $str=shift;
  my $count = 0;
  while ($str) {
    $count += chop($str);
  }
  $count;
}


sub max_ones_fast {
  ($_[0] =~ tr/1/1/);
}

sub get_pool_roulette_wheel {
  my $population = shift || croak "No population here";
  my $fitness_of = shift || croak "need stuff evaluated";
  my $need = shift || croak "I need to know the new population size";
  my $total_fitness = shift || croak "I need the total fitness";

  my @wheel = map( $fitness_of->{$_}/$total_fitness, @$population);
  my @slots = spin( \@wheel, scalar(@$population));
#  my $slots = scalar(@$population);
#  my @slots = map( $_*$slots, @wheel );;
  my @pool;
  my $index = 0;
  do {
    my $p = $index++ % @slots;
    my $copies = $slots[$p];
    for (1..$copies) {
      push @pool, $population->[$p];
    }
  } while ( @pool < $need );
  
  @pool;
}

sub get_pool_binary_tournament {
  my $population = shift || croak "No population here";
  my $fitness_of = shift || croak "need stuff evaluated";
  my $need = shift || croak "I need to know the new population size";

  my $total_fitness = 0;
  my @pool;
  my $population_size = @$population;
  do {
    my $one = $population->[rand( $population_size )];
    my $another = $population->[rand( $population_size )];
    if ( $fitness_of->{$one} > $fitness_of->{$another} ) {
      push @pool, $one;
    } else {
      push @pool, $another;
    }
  } while ( @pool < $need );
  
  @pool;
}

sub spin {
   my ( $wheel, $slots ) = @_;
   return map( $_*$slots, @$wheel );
}

sub produce_offspring {
  my $pool = shift || croak "Pool missing";
  my $offspring_size = shift || croak "Population size needed";
  my @population = ();
  my $population_size = scalar( @$pool );
  for ( my $i = 0; $i < $offspring_size/2; $i++ )  {
    my $first = $pool->[rand($population_size)];
    my $second = $pool->[rand($population_size)];
    
    push @population, crossover( $first, $second );
  }
  map( $_ = mutate($_), @population );
  return @population;
}

sub mutate {
  my $chromosome = shift;
  my $mutation_point = int(rand( length( $chromosome )));
  substr($chromosome, $mutation_point, 1,
	 ( substr($chromosome, $mutation_point, 1) eq 1 )?0:1 );
  return $chromosome;
}

sub crossover {
  my ($chromosome_1, $chromosome_2) = @_;
  my $length = length( $chromosome_1 );
  my $xover_point_1 = int rand( $length - 2 );
  my $range = 1 + int rand ( $length - $xover_point_1 );
  my $swap_chrom = $chromosome_1;
  substr($chromosome_1, $xover_point_1, $range,
	 substr($chromosome_2, $xover_point_1, $range) );
  substr($chromosome_2, $xover_point_1, $range,
	 substr($swap_chrom, $xover_point_1, $range) );
  return ( $chromosome_1, $chromosome_2 );
}

sub single_generation {
  my $population = shift || croak "No population";
  my $fitness_of = shift || croak "No fitness cache";
  my $total_fitness = shift;
  if ( !$total_fitness ) {
    map( $total_fitness += $fitness_of->{$_}, @$population);
  }
  my $population_size = @{$population};
  my @best = rnkeytop { $fitness_of->{$_} } 2 => @$population; # Extract elite
  my @reproductive_pool = get_pool_roulette_wheel( $population, $fitness_of, 
						   $population_size, $total_fitness ); # Reproduce
  my @offspring = produce_offspring( \@reproductive_pool, $population_size - 2 ); #Obtain offspring
  unshift( @offspring, @best ); #Insert elite at the beginning
  @offspring; # return
}

"010101"; # Magic true value required at end of module
__END__

=head1 NAME

Algorithm::Evolutionary::Simple - Run a simple, canonical evolutionary algorithm in Perl


=head1 VERSION

This document describes Algorithm::Evolutionary::Simple version 0.1.2


=head1 SYNOPSIS

    use Algorithm::Evolutionary::Simple qw( random_chromosome max_ones max_ones_fast
					get_pool_roulette_wheel get_pool_binary_tournament produce_offspring single_generation);

   my @population;
   my %fitness_of;
   for (my $i = 0; $i < $number_of_strings; $i++) {
      $population[$i] = random_chromosome( $length);
      $fitness_of{$population[$i]} = max_ones( $population[$i] );
    }
  
    my @best;
    my $generations=0;
    do {
        my @pool; 
        if ( $generations % 2 == 1 ) { 
           get_pool_roulette_wheel( \@population, \%fitness_of, $number_of_strings );
        } else {
          get_pool_binary_tournament( \@population, \%fitness_of, $number_of_strings );
        }
        my @new_pop = produce_offspring( \@pool, $number_of_strings/2 );
        for my $p ( @new_pop ) {
	    if ( !$fitness_of{$p} ) {
	        $fitness_of{$p} = max_ones( $p );
	    }
        }
       @best = rnkeytop { $fitness_of{$_} } $number_of_strings/2 => @population;
       @population = (@best, @new_pop);
       print "Best so far $best[0] with fitness $fitness_of{$best[0]}\n";	 
   } while ( ( $generations++ < $number_of_generations ) and ($fitness_of{$best[0]} != $length ));


=head1 DESCRIPTION

Assorted functions needed by an evolutionary algorithm, mainly for demos and simple clients.


=head1 INTERFACE 

=head2 random_chromosome( $length )

Creates a binary chromosome, with uniform distribution of 0s and 1s,
and returns it as a string.

=head2 max_ones( $string )

Classical function that returns the number of ones in a binary string.


=head2 max_ones_fast( $string )

Faster implementation of max_ones.

=head2 spin($wheel, $slots )

Mainly for internal use, $wheel has the normalized probability, and
    $slots  the number of individuals to return.

=head2 single_generation( $population_arrayref, $fitness_of_hashref )

Applies all steps to arrive to a new generation, except
evaluation. Keeps the two best for the next generation.

=head2 get_pool_roulette_wheel( $population_arrayref, $fitness_of_hashref, $how_many_I_need )

Obtains a pool of new chromosomes using fitness_proportional selection


=head2 get_pool_binary_tournament( $population_arrayref, $fitness_of_hashref, $how_many_I_need )

Obtains a pool of new chromosomes using binary tournament, a greedier method.

=head2 produce_offspring( $population_hashref, $how_many_I_need )

Uses mutation first and then crossover to obtain a new population

=head2 mutate( $string )

Bitflips a  a single point in the binary string

=head2 crossover( $one_string, $another_string )

Applies two-point crossover to both strings, returning them changed

=head1 DIAGNOSTICS

Will complain if some argument is missing.


Algorithm::Evolutionary::Simple requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Sort::Key::Top> for efficient sorting. 

=head1 SEE ALSO

There are excellent evolutionary algorithm libraries out there; see
    for instance L<AI::Genetic::Pro>

=head1 BUGS AND LIMITATIONS

It's intended for simplicity, not flexibility. If you want a
    full-featured evolutionary algorithm library, check L<Algorithm::Evolutionary>

Please report any bugs or feature requests to
C<bug-algorithm-evolutionary-simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the GPL v3 licence.


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
