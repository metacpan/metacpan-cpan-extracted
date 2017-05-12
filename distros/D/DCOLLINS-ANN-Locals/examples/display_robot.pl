#!/usr/bin/perl
use strict;
use warnings;

use AI::ANN::Evolver;
use DCOLLINS::ANN::Robot;
use DCOLLINS::ANN::SimWorld;
use Data::Dumper;
use Storable;
$Storable::Deparse = 1;
$Storable::Eval = 1;

$|=1;

my $num=$ARGV[0];

my $robot = retrieve("winner_generation_$num.robot");

my $w=new DCOLLINS::ANN::SimWorld (show_field => 1);
$w->run_robot($robot);
