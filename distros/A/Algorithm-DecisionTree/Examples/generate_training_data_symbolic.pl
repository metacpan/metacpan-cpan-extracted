#!/usr/bin/perl -w

##  generate_training_data_symbolic.pl

use strict;
use Algorithm::DecisionTree;

my $parameter_file = "param_symbolic.txt";
my $output_training_datafile = "training_symbolic2.csv";

my $training_data_gen = TrainingDataGeneratorSymbolic->new( 
                              output_training_datafile => $output_training_datafile,
                              parameter_file    => $parameter_file,
                              number_of_samples_for_training => 200,
                        );

$training_data_gen->read_parameter_file_symbolic();
$training_data_gen->gen_symbolic_training_data();

