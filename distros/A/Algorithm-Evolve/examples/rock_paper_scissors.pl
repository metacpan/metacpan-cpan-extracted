#!/usr/bin/perl
use strict;
use warnings;

## this example script has POD -- check it out!

use StringEvolver alphabet => [qw/R P S/], mutation_rate => 0.05;
our @ISA = ('StringEvolver');

use lib '../lib';
use Algorithm::Evolve;

sub compare {
    my ($class, $crit1, $crit2) = @_;

    my ($string1, $string2) = ($crit1->gene, $crit2->gene);
    my ($score1, $score2)   = (0, 0);
    my $length              = length($string1);
    my $offset1             = int rand $length;
    my $offset2             = int rand $length;

    ## .. and wrap around
    $string1 x= 2;
    $string2 x= 2;

    for (1 .. $length) {
        my $char1 = substr($string1, $offset1++, 1);
        my $char2 = substr($string2, $offset2++, 1);

        next if $char1 eq $char2; ## tie

        if (($char1 eq 'R' && $char2 eq 'S') or
            ($char1 eq 'S' && $char2 eq 'P') or
            ($char1 eq 'P' && $char2 eq 'R'))
        {
            $score1++;
        } else {
            $score2++;
        }
    }

    return $score1 <=> $score2;
}

sub callback {
    my $p = shift;
    my %occurences;

    for (@{$p->critters}) {
        my $gene = $_->gene;
        $occurences{R} += $gene =~ tr/R/R/;
        $occurences{P} += $gene =~ tr/P/P/;
        $occurences{S} += $gene =~ tr/S/S/;
    }
    print "$occurences{R} $occurences{P} $occurences{S}\n";

    $p->suspend if $p->generations >= 1000;
}

my $p = Algorithm::Evolve->new(
    critter_class    => 'main',
    selection        => 'gladitorial',
    parents_per_gen  => 10,
    size             => 80,
    callback         => \&callback,
    random_seed      => shift
);

$p->start;

__END__

=head1 NAME

rock_paper_scissors.pl - Rock Paper Scissors co-evolution example for
Algorithm::Evolve

=head1 DESCRIPTION

This simulation uses StringEvolver.pm as a base class for crossover,
random initialization, and mutation. Unlike F<examples/string_evolver.pl>,
this is a co-evolving system where fitness is not absolute, but based
on a critter's ability to play Rock, Paper, Scissors against the other
members of the population.

In co-evolution, population members are chosen for selection and replacement
using the C<compare> method. In our critter class, we override the default
C<compare> method. Our new C<compare> method
uses each string gene as a sequence of Rock, Paper, and Scissors moves. The
gene who wins the most turns is the winner. Notice how we pick a random spot
in the string genes to start at, and wrap back to the beginning, taking each
move exactly once.

At each generation, the total number of Rock, Paper, and Scissors
encodings in the population are tallied and printed. If you graph the
output in something like gnuplot, you will probably notice that the
population cycles between Rock, Paper, and Scissors being the most
prevalent move. This is the command in gnuplot I used to view the output
from this script:

   gnuplot> plot 'output' using :1 title 'Rock' with lines, \
   >             'output' using :2 title 'Paper' with lines, \
   >             'output' using :3 title 'Scissors' with lines

Notice how (in general) Scissors overtakes Paper which overtakes Rock which
overtakes scissors, etc.

In general, it's more interesting to evolve "thinking" strategies for Rock,
Paper, Scissors (or any game), than just a fixed sequence of moves. Such
strategies include state machines and genetic programming structures.
Hopefully, though, this example illustrates the ease with which you could
transparently swap in a different type of strategy for this game.
