#!/usr/bin/perl
use strict;
use warnings;

use AI::ANN::Evolver;
use DCOLLINS::ANN::Robot;
use DCOLLINS::ANN::SimWorld;
use Data::Dumper;
use List::Util qw(max min);
use Storable qw(dclone store retrieve);
$Storable::Deparse = 1;
$Storable::Eval = 1;
use Math::Libm qw(tan);

$|=1;

my $trainingdata = [[]];
# 'neutral' input is:          4    5    6    7    8    9    10   11   12   13
my $neutral = [0.5, 0.5, 0, 0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
$trainingdata->[0] = dclone($neutral);
$trainingdata->[0]->[0] = 0; # Dead battery
$trainingdata->[0]->[6] = 1; # Center proximity
$trainingdata->[0]->[9] = 0; # X
$trainingdata->[0]->[10] = 1; # Y
$trainingdata->[0]->[11] = 1; # Facing North
$trainingdata->[0]->[12] = 0;
$trainingdata->[0]->[13] = 0;
$trainingdata->[0]->[14] = 0;
$trainingdata->[1] = [0, 0, 2, 0, 0]; 
$trainingdata->[2] = dclone($neutral);
$trainingdata->[2]->[0] = 0; # Dead battery
$trainingdata->[2]->[6] = 1; # Center proximity
$trainingdata->[2]->[9] = 0; # X
$trainingdata->[2]->[10] = 1; # Y
$trainingdata->[2]->[11] = 0; # Facing South
$trainingdata->[2]->[12] = 1;
$trainingdata->[2]->[13] = 0;
$trainingdata->[2]->[14] = 0;
$trainingdata->[3] = [0, 0, 0, 2, 0]; 
$trainingdata->[4] = dclone($neutral);
$trainingdata->[4]->[0] = 0; # Dead battery
$trainingdata->[4]->[6] = 1; # Center proximity
$trainingdata->[4]->[9] = 0; # X
$trainingdata->[4]->[10] = 1; # Y
$trainingdata->[4]->[11] = 0; # Facing East
$trainingdata->[4]->[12] = 0;
$trainingdata->[4]->[13] = 1;
$trainingdata->[4]->[14] = 0;
$trainingdata->[5] = [2, 0, 0, 0, 0]; 
$trainingdata->[6] = dclone($neutral);
$trainingdata->[6]->[0] = 0; # Dead battery
$trainingdata->[6]->[6] = 1; # Center proximity
$trainingdata->[6]->[9] = 0; # X
$trainingdata->[6]->[10] = 1; # Y
$trainingdata->[6]->[11] = 0; # Facing West
$trainingdata->[6]->[12] = 0;
$trainingdata->[6]->[13] = 0;
$trainingdata->[6]->[14] = 1;
$trainingdata->[7] = [0, 2, 0, 0, 0]; 
$trainingdata->[8] = dclone($neutral);
$trainingdata->[8]->[0] = 0; # Dead battery
$trainingdata->[8]->[6] = 1; # Center proximity
$trainingdata->[8]->[9] = 1; # X
$trainingdata->[8]->[10] = 0; # Y
$trainingdata->[8]->[11] = 1; # Facing North
$trainingdata->[8]->[12] = 0;
$trainingdata->[8]->[13] = 0;
$trainingdata->[8]->[14] = 0;
$trainingdata->[9] = [2, 0, 0, 0, 0]; 
$trainingdata->[10] = dclone($neutral);
$trainingdata->[10]->[0] = 0; # Dead battery
$trainingdata->[10]->[6] = 1; # Center proximity
$trainingdata->[10]->[9] = 1; # X
$trainingdata->[10]->[10] = 0; # Y
$trainingdata->[10]->[11] = 0; # Facing South
$trainingdata->[10]->[12] = 1;
$trainingdata->[10]->[13] = 0;
$trainingdata->[10]->[14] = 0;
$trainingdata->[11] = [0, 2, 0, 0, 0]; 
$trainingdata->[12] = dclone($neutral);
$trainingdata->[12]->[0] = 0; # Dead battery
$trainingdata->[12]->[6] = 1; # Center proximity
$trainingdata->[12]->[9] = 1; # X
$trainingdata->[12]->[10] = 0; # Y
$trainingdata->[12]->[11] = 0; # Facing East
$trainingdata->[12]->[12] = 0;
$trainingdata->[12]->[13] = 1;
$trainingdata->[12]->[14] = 0;
$trainingdata->[13] = [0, 0, 0, 2, 0]; 
$trainingdata->[14] = dclone($neutral);
$trainingdata->[14]->[0] = 0; # Dead battery
$trainingdata->[14]->[6] = 1; # Center proximity
$trainingdata->[14]->[9] = 1; # X
$trainingdata->[14]->[10] = 0; # Y
$trainingdata->[14]->[11] = 0; # Facing West
$trainingdata->[14]->[12] = 0;
$trainingdata->[14]->[13] = 0;
$trainingdata->[14]->[14] = 1;
$trainingdata->[15] = [0, 0, 2, 0, 0]; 
$trainingdata->[16] = dclone($neutral);
$trainingdata->[16]->[0] = 1; # Good battery
$trainingdata->[16]->[6] = 1; # Center proximity
$trainingdata->[17] = [0, 0, 2, 2, 0]; # Go Somewhere!
$trainingdata->[18] = dclone($neutral);
$trainingdata->[18]->[0] = 1; # Good battery
$trainingdata->[18]->[4] = 1; 
$trainingdata->[18]->[5] = 1; 
$trainingdata->[18]->[6] = 0; # Center proximity
$trainingdata->[19] = [2, 0, 0, 0, 0];
$trainingdata->[20] = dclone($neutral);
$trainingdata->[20]->[0] = 1; # Good battery
$trainingdata->[20]->[6] = 0; # Center proximity
$trainingdata->[20]->[7] = 1; 
$trainingdata->[20]->[8] = 1; 
$trainingdata->[21] = [0, 2, 0, 0, 0];

my $robots = [[]];
my $results = [[]];
for (my $i = 0; $i < 100; $i++) {
    $robots->[0]->[$i]=new DCOLLINS::ANN::Robot;
    for (my $j = 0; $j < 22; $j += 2 ) {
        $robots->[0]->[$i]->backprop(dclone($trainingdata->[$j]), dclone($trainingdata->[$j+1]));
    }
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
my $max_age = 500;
my $last_best_age = 0;
my $score90 = 0;
while (1) {
    $gen_score = 0;
    $min_score = 0;
    $max_score = 0;
    $gen_age = 0;
    $min_age = 0;
    $last_best_age = min($max_age, 1500);
    print "Generation $generation: Allowing at most ". $last_best_age*2 ." turns.\n";
    $max_age = 0;
    for (my $i = 0; $i < 100; $i++) {
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
        if ($i % 5) {print '.'}
        if ($i == 90) {$score90 = $score}
    }
    print "\n";
    my $avg_score = $gen_score/100;
    my $avg_age = $gen_age/100;
    my @sorted = sort {$results->[$generation]->[$b]->{'fitness'} <=> $results->[$generation]->[$a]->{'fitness'}} 0..99;
#use Data::Dumper; print Dumper($robots->[$generation]->[$sorted[0]]);
print ref $robots->[$generation]->[$sorted[0]]; print "\n";
    store($robots->[$generation]->[$sorted[0]], "winner_generation_$generation.robot");
    for (my $i = 0; $i < 90; $i+=10) {
        for (my $j = 0; $j < 10; $j++) {
            if ($i+$j < 85) {
                $robots->[$generation+1]->[$i+$j] = $e->mutate($robots->[$generation]->[$sorted[$j]]);
            } else {
                $robots->[$generation+1]->[$i+$j] = $e->crossover($robots->[$generation]->[$sorted[$j-5]],$robots->[$generation]->[$sorted[$j]]);
            }
            if (($i+$j) % 9) {print ':'}
        }
    }
    print "\n";
    for (my $j = 0; $j < 10; $j++) {
        $robots->[$generation+1]->[90+$j] = $robots->[$generation]->[$sorted[$j]];
    }
    print "Generation is $generation. Ages are $min_age, $avg_age, $max_age.\n";
    print "Scores are $min_score, $avg_score, $max_score.\n";
    print "Number 90 (theoretical best from last round) had $score90.\n";
    if ($avg_score > 15) {
        print "Halting criterion met! Exiting...\n";
        last;
    }
    $generation++;
}
