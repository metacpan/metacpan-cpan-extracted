#!/usr/bin/perl

## A trivial string evolver simulation using StringEvolver.pm. It evolves
## strings of all 1's, the "Hello World" of evoluationary algorithms. ;)

use lib '../lib';
use Algorithm::Evolve;
use StringEvolver;

sub callback {
    my $pop = shift;
    
    ## Print out statistics every 50 generations
    unless ($pop->generations % 50) {
        printf "generations:%d best_fit:%d avg_fitness:%f\n",
            $pop->generations, $pop->best_fit->fitness, $pop->avg_fitness;
    }
    
    ## We can even change some things part-way through if we felt like it!

#    if ($pop->avg_fitness > 19 and $pop->replacement ne 'absolute') {
#        $pop->replacement('absolute');
#        $pop->selection('absolute');
#        $pop->parents_children_per_gen(2,2);
#    }
    
    ## End the simulation after 500 generations
    $pop->suspend if $pop->generations >= 500;
}

my $pop = Algorithm::Evolve->new(
    critter_class    => 'StringEvolver',
    selection        => 'rank',
    parents_per_gen  => 8,
    size             => 200,
    callback         => \&callback,
    random_seed      => shift
);

$pop->start;
