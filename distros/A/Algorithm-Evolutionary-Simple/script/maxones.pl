#!/usr/bin/env perl

use strict;
use warnings;

use lib qw( ../lib lib );

use version; our $VERSION = qv('0.0.3');
use Algorithm::Evolutionary::Simple qw( random_chromosome max_ones_fast
					single_generation);
use Sort::Key::Top qw(rnkeytop);

my $length = shift || 64;
my $number_of_strings = shift || 64;

my @population;
my %fitness_of;
my $total_fitness;
for (my $i = 0; $i < $number_of_strings; $i++) {
  $population[$i] = random_chromosome( $length);
  $fitness_of{$population[$i]} = max_ones_fast( $population[$i] );
  $total_fitness += $fitness_of{$population[$i]};
}
  
my $evaluations=$#population+1;

do {
    @population = single_generation(  \@population, \%fitness_of, $total_fitness  );
    $total_fitness = 0;
    for my $p ( @population ) {
	if ( !$fitness_of{$p} ) {
	    $fitness_of{$p} = max_ones_fast( $p );
	}
	$total_fitness += $fitness_of{$p};
    }
    $evaluations += $#population -1; # Two are kept from previous generation
    print "Best so far $population[0] with fitness $fitness_of{$population[0]} and evaluated $evaluations\n";	 
} while  ($fitness_of{$population[0]} != $length );



__END__

=head1 NAME

simple-EA.pl - A simple evolutionary algorithm that uses the functions in the library


=head1 VERSION

This document describes simple-EA.pl version 0.0.3


=head1 SYNOPSIS

    % chmod +x simple-EA.pl
    % simple-EA.pl [Run with default values]
    % simple-EA.pl 64 128 200 [Run with 64 chromosomes, population 128 for 200 generations]

=head1 DESCRIPTION

Run a simple evolutionary algorithm using functions in the
module. Intended mainly for teaching and modification, not for
production. 


