#!/usr/bin/perl
use strict;
use warnings;

use AI::ANN::Evolver;
use DCOLLINS::ANN::Robot;
use DCOLLINS::ANN::SimWorld;
use Data::Dumper;
use List::Util qw(max min);
use Storable;
$Storable::Deparse = 1;
$Storable::Eval = 1;
use Math::Libm qw(tan);

$|=1;

my $robots = [[]];
my $results = [[]];
for (my $i = 0; $i < 400; $i++) {
    $robots->[0]->[$i]=new DCOLLINS::ANN::Robot;
}
my $w=new DCOLLINS::ANN::SimWorld ( show_progress => 1 );
my $e=new AI::ANN::Evolver ( min_value => -2,
    max_value => 2,
    mutation_chance => 0.12,
    mutation_amount => sub { 0.12 * tan( 2 * rand() - 1 ) },
    add_link_chance => 0,
    kill_link_chance => 0,
    sub_crossover_chance => 0.01 );
my $generation = 0;
my $gen_score = 0;
my $min_score = 0;
my $max_score = 0;
my $gen_age = 0;
my $min_age = 0;
my $max_age = 750;
my $last_best_age = 0;
my $score350 = 0;
while (1) {
    $gen_score = 0;
    $min_score = 0;
    $max_score = 0;
    $gen_age = 0;
    $min_age = 0;
    $last_best_age = min($max_age, 750);
    print "Generation $generation: Allowing at most ". $last_best_age*2 ." turns.\n";
    $max_age = 0;
    for (my $i = 0; $i < 400; $i++) {
        $results->[$generation]->[$i]=$w->run_robot($robots->[$generation]->[$i], $last_best_age*2);
        my $score = $results->[$generation]->[$i]->{'fitness'};
        my $age = $results->[$generation]->[$i]->{'age'};
        $gen_score += $score;
        $gen_age += $age;
        if ($i == 0) {
            $min_score = $max_score = $score;
            $min_age = $max_age = $age;
        } else {
            $min_score = $score if $score < $min_score;
            $max_score = $score if $score > $max_score;
            $min_age = $age if $age < $min_age;
            $max_age = $age if $age > $max_age;
        }
        if ($i % 5 == 4) {print '.'}
        if ($i == 350) {$score350 = $score}
    }
    print "\n";
    my $avg_score = $gen_score/400;
    my $avg_age = $gen_age/400;
    my @sorted = sort {$results->[$generation]->[$b]->{'fitness'} <=> $results->[$generation]->[$a]->{'fitness'}} 0..399;
    store $robots->[$generation]->[$sorted[0]], "winner_generation_$generation.robot";
    for (my $i = 0; $i < 300; $i+=50) {
        for (my $j = 0; $j < 50; $j++) {
            $robots->[$generation+1]->[$i+$j] = $e->mutate_gaussian($robots->[$generation]->[$sorted[$j]]);
        }
    }
    for (my $i = 0; $i < 50; $i++) {
        $robots->[$generation+1]->[300+$i] = $e->crossover($robots->[$generation]->[$sorted[$i]], $robots->[$generation]->[$sorted[150-$i]]);
    }
    print "\n";
    for (my $j = 0; $j < 50; $j++) {
        $robots->[$generation+1]->[350+$j] = $robots->[$generation]->[$sorted[$j]];
    }
    delete $robots->[$generation];
    print "Generation is $generation. Ages are $min_age, $avg_age, $max_age.\n";
    print "Scores are $min_score, $avg_score, $max_score.\n";
    print "Number 350 (theoretical best from last round) had $score350.\n";
    if ($avg_score > 12) {
        print "Halting criterion met! Exiting...\n";
        last;
    }
    $generation++;
}
