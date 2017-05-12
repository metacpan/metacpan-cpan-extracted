#!/usr/bin/perl -w

##  generate_training_and_test_data_numeric.pl

use strict;
use Algorithm::DecisionTree;

my $parameter_file = "param_numeric.txt";
my $output_training_csv_file = "training4.csv";
my $output_test_csv_file = "test4.csv";

my $training_data_gen = TrainingAndTestDataGeneratorNumeric->new( 
                         output_training_csv_file => $output_training_csv_file,
                         output_test_csv_file     => $output_test_csv_file,
                         parameter_file           => $parameter_file,
                         number_of_samples_for_training => 200,
                         number_of_samples_for_testing => 20,
                        );

$training_data_gen->read_parameter_file_numeric();
$training_data_gen->gen_numeric_training_and_test_data_and_write_to_csv();



