#!/usr/bin/perl
use lib '../lib';

## This example is geared towards those who are familiar with a certain
## infamous PerlMonks writeup...

##############################################################################
## Genetic Programming or breeding Perls (http://perlmonks.org/?node_id=31147)
## is one of the all-time most popular nodes on PerlMonks. It's a great
## example of genetic programming, the catch being that it uses eval to breed
## real Perl programs. The goal is to find a Perl expression that evaluates to
## a target number. This is a reimplementation of that writeup's code using 
## Algorithm::Evolve to (hopefully) demonstrate the features of A::E.
##############################################################################

unless (@ARGV) {
    print "Usage: $0 target\n";
    print "A large target is hard to find. Start with something near 100.\n";
    exit;
}
our $TARGET = shift;

##############################################################################
## Now set up 'main' as a critter class. That means objects of the 'main'
## class are critters, which are the members of the evolving population. We
## use a base class that has default methods necessary for A::E to use it as a
## critter class (mutation, fitness, crossover, etc). This base class uses an
## array for the "gene" of the critter. Each item in the array is a valid Perl
## statement (a member of the alphabet). As you can see, you could easily add
## more statements to the alphabet, or change the number of Perl statements in
## the array genes, etc.
##############################################################################

use ArrayEvolver gene_length => 30,
                 alphabet => [qw( $x+=1; $x=$y; $x|=$y; $x+=$y; $y=$x; )],
                 mutation_rate => (1/30);
our @ISA = 'ArrayEvolver';

############################################################################
## We override the default inherited fitness method. In A::E, fitness is
## *maximized*. If were were minimizing fitness, we could just use
## "abs( $TARGET - eval )" as the fitness measure. The fitness measure we 
## actually use gives the highest fitness if the result of the Perl code is
## $TARGET, and gives lower fitness the farther away the result is from the
## target.
############################################################################

sub fitness {
    my $self = shift;
    my $f = $TARGET - abs( $TARGET - eval($self->as_perl_code) );
    return ($f < 0 ? 0 : $f);
}

sub as_perl_code {
    my $self = shift;
    return 'my $x=1; my $y=1; ' . join(" ", @{$self->gene});
}

##############################################################################
## Now set up the population. We tell A::E how we want critters to be selected
## and replaced, how many breeding events per generation, the size of the
## population, etc. We also define a callback sub that gets called after every
## every generation. Among other things, its most important task is to
## determine the criteria for stopping the algorithm.
##############################################################################

use Algorithm::Evolve;
Algorithm::Evolve->new(
    critter_class   => 'main',
    selection       => 'roulette',
    replacement     => 'rank',
    parents_per_gen => 2,
    size            => 200,
    callback        => \&callback,
)->start;

sub callback {
    my $p = shift;

    if ($p->best_fit->fitness == $TARGET) {
        $p->suspend;
        printf "Solution found after %d generations:\n%s\n",
                    $p->generations, $p->best_fit->as_perl_code;
    }
    
    if ($p->generations == 100_000) {
        $p->suspend;
        print "Timed out after 100,000 generations.. try a smaller target\n";
    }
}
