#!/usr/bin/perl

####
# annealing_tests.t:  Test the AI::SimulatedAnnealing module.
#
# Usage:
#
#     perl -w annealing_tests.t market_distances.csv
####
use 5.010001;
use strict;
use warnings;
use utf8;

use English "-no_match_vars";
use List::Util ("max", "min");

use AI::SimulatedAnnealing;
use Text::BSV::BsvFileReader;

# Probability enumeration:
package Probability;

our $ONE_FIFTH  = 5;
our $ONE_FOURTH = 4;
our $ONE_THIRD  = 3;
our $ONE_HALF   = 2;

# Redeclaration of the main package:
package main;

# Constants:
my $POUND     = "#";
my $SQ        = "'";
my $DQ        = "\"";
my $SEMICOLON = ";";
my $CR        = "\r";
my $LF        = "\n";
my $SPACE     = " ";
my $EMPTY     = "";
my $TRUE      = 1;
my $FALSE     = 0;

my $CYCLES_PER_TEMPERATURE = 1_250;

# Main script:

# Get the input file path:
my $bsv_file_path = $ARGV[0];

unless (scalar @ARGV) {
    die "ERROR:  No command-line argumment.  Please provide the path to a "
      . "valid BSV (or simple CSV) file containing market distances.\n";
} # end unless

# Create a reader for the BSV file:
my $bsv_file_reader;

eval {
    $bsv_file_reader = Text::BSV::BsvFileReader->new($bsv_file_path);
};

if ($EVAL_ERROR) {
    my $exception = $EVAL_ERROR;

    given ($exception->get_type()) {
        when ($Text::BSV::Exception::FILE_NOT_FOUND) {
            say STDERR "$DQ$bsv_file_path$DQ is not a valid file path.";
            exit(1);
        }
        when ($Text::BSV::Exception::IO_ERROR) {
            say STDERR "Couldn't open $DQ$bsv_file_path$DQ for reading.";
            exit(1);
        }
        when ($Text::BSV::Exception::INVALID_DATA_FORMAT) {
            say STDERR "Invalid BSV data:  " . $exception->get_message();
            exit(1);
        }
        default {
            say STDERR $exception->get_message();
            exit(1);
        } # end when
    } # end given
} # end if

# Generate a list of distances for each probability from the data in the
# BSV file:
my $field_names = $bsv_file_reader->get_field_names();
my @mapped_distances; # indexes 2-5 = Probability constants;
                      # values = references to number arrays

for my $p (2..5) {
    $mapped_distances[$p] = [];
} # next $p

unless ($field_names->[0] eq "Time"
  && $field_names->[1] =~ /$Probability::ONE_FIFTH\z/s
  && $field_names->[2] =~ /$Probability::ONE_FOURTH\z/s
  && $field_names->[3] =~ /$Probability::ONE_THIRD\z/s
  && $field_names->[4] =~ /$Probability::ONE_HALF\z/s) {
    die "ERROR:  The input file does not contain market-distance data in "
      . "the expected format.\n";
} # end unless

while ($bsv_file_reader->has_next()) {
    my $record;
    my $dex;

    eval {
        $record = $bsv_file_reader->get_record();
    };

    if ($EVAL_ERROR) {
        given ($EVAL_ERROR->get_type()) {
            when ($Text::BSV::Exception::INVALID_DATA_FORMAT) {
                die "ERROR:  Invalid BSV data:  "
                  . $EVAL_ERROR->get_message() . $LF;
            }
            default {
                die "ERROR:  " . $EVAL_ERROR->get_message() . $LF;
            } # end when
        } # end given
    } # end if

    $dex = $record->{"Time"} - 3;

    unless ($dex >= 0
      && $dex <= scalar($mapped_distances[$Probability::ONE_FIFTH])) {
        die "ERROR:  The input file does not contain market-distance data "
          . "in the expected format.\n";
    } # end unless

    for my $p (2..5) {
        push @{ $mapped_distances[$p] }, $record->{$field_names->[6 - $p]};
    } # next $p
} # end while

unless (scalar @{ $mapped_distances[$Probability::ONE_FIFTH] } == 61) {
    die "ERROR:  The input file does not contain the expected number of "
      . "records.\n";
} # end unless

# Perform simulated annealing to optimize the coefficients for each of the
# four probabilities, and then print the results to the console:
for my $p (2..5) {
    my $cost_function = cost_function_factory($mapped_distances[$p]);
    my $optimized_coefficients;
    my @number_specs;

    push @number_specs,
      {"LowerBound" =>  0.0, "UpperBound" => 3.0, "Precision" => 3};
    push @number_specs,
      {"LowerBound" => -1.0, "UpperBound" => 5.0, "Precision" => 3};
    push @number_specs,
      {"LowerBound" => -4.0, "UpperBound" => 0.0, "Precision" => 3};

    $optimized_coefficients = anneal(
      \@number_specs, $cost_function, $CYCLES_PER_TEMPERATURE);

    # Print the results for this probability to the console:
    say "\nProbability:  1/$p";
    printf("Coefficients:  a = %1.3f; b = %1.3f; c= %1.3f\n",
      $optimized_coefficients->[0],
      $optimized_coefficients->[1],
      $optimized_coefficients->[2]);
    say "Cost:  " . $cost_function->($optimized_coefficients);
} # next $p

# Perform an annealing test with integers that triggers brute-force analysis
# and uses an anonymous cost function that minimizes this sum:
#
#     (10 * abs(23 - val)) + (the total range of a, b, and c)
#
# where "val" is the result of following expression:
#
#     (a * (x ** 2)) + bx + c
#
# in which x = 3:
my $abc;
my @number_specs;

push @number_specs,
  {"LowerBound" =>  1.9, "UpperBound" => 4, "Precision" => 0};
push @number_specs,
  {"LowerBound" =>  0.0, "UpperBound" => 2, "Precision" => 0};
push @number_specs,
  {"LowerBound" => -4.0, "UpperBound" => 8, "Precision" => 0};

$abc = anneal(\@number_specs,
  sub {
    my $nums = $_[0];
    my $range = max(@{ $nums }) - min(@{ $nums });
    my $val = ($nums->[0] * 9) + ($nums->[1] * 3) + $nums->[2];
    my $cost = $range + (10 * abs(23 - $val));

    return $cost;
  }, 120);

say "\nHere are a, b, and c:  " . $abc->[0] . ", "
  . $abc->[1] . ", " . $abc->[2];

# Helper functions:

# The cost_function_factory() takes a reference to an array containing
# real-world market distances and returns a reference to a cost function.
# The cost function takes a reference to an array of three coefficients,
# and returns the mean absolute percentage deviation of the calculated
# results from the real-world results based on this formula:
#
#     (a * sqrt(x + b)) + c
#
# where x is a number of trading days in the range 3 to 63.
sub cost_function_factory {
    my $real_world_distances = $_[0];
    my $current_coefficients;

    my $calculate_distance
      = sub {
        my $trading_days = $_[0];
        my $distance = ($current_coefficients->[0]
          * sqrt($trading_days + $current_coefficients->[1]))
          + $current_coefficients->[2];

        return $distance;
      };

    my $cost_function
      = sub {
        my $coefficients = $_[0];

        my @calculated_distances;
        my $cumulative_deviation;
        my $cost;

        $current_coefficients = $coefficients;

        for my $trading_days (3..63) {
            push @calculated_distances,
              $calculate_distance->($trading_days);
        } # next $trading_days

        for my $dex (0..60) {
            $cumulative_deviation
              += (100 * abs($calculated_distances[$dex]
              - $real_world_distances->[$dex])
              / $real_world_distances->[$dex]);
        } # next $dex

        $cost = $cumulative_deviation / 61;

        return $cost;
      };

    return $cost_function;
} # end sub
