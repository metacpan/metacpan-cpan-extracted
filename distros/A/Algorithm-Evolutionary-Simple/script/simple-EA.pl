#!perl

use strict;
use warnings;

use lib qw( ../lib lib );

use version; our $VERSION = qv('0.0.3');
use Algorithm::Evolutionary::Simple qw( random_chromosome max_ones 
					get_pool_roulette_wheel get_pool_binary_tournament produce_offspring  );  
use Sort::Key::Top qw(rnkeytop);

my $length = shift || 64;
my $number_of_strings = shift || 64;
my $number_of_generations = shift || 100;
my $pool = shift || "roulette";


my @population;
my %fitness_of;
for (my $i = 0; $i < $number_of_strings; $i++) {
  $population[$i] = random_chromosome( $length);
  $fitness_of{$population[$i]} = max_ones( $population[$i] );
}

my $get_pool;
if ( $pool eq "roulette" ) {
  $get_pool = \&get_pool_roulette_wheel;
}   else {
  $get_pool = \&get_pool_binary_tournament;
}
my @best;
my $generations=0;
do {
    my @pool = $get_pool->( \@population, \%fitness_of, $number_of_strings );
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



__END__

=head1 NAME

simple-EA.pl - A simple evolutionary algorithm that uses the functions in the library


=head1 VERSION

This document describes simple-EA.pl version 0.0.3

=head1 SYNOPSIS

    % chmod +x simple-EA.pl
    % simple-EA.pl [Run with default values]
    % simple-EA.pl 64 128 200 [Run with 64 chromosomes, population 128 for 200 generations]
    % simple-EA.pl 64 128 250 binary [Use binary tournament instead of the default roulete wheel]

=head1 DESCRIPTION

Run a simple evolutionary algorithm using functions in the
module. Intended mainly for teaching and modification, not for
production (but can be useful too as a baseline tool)


