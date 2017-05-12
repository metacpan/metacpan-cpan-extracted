####
# SimulatedAnnealing.pm:  A Perl module that exports a single public
# function, anneal(), for optimizing a list of numbers according to a
# specified cost function.
#
####
#
# Copyright 2010 by Benjamin Fitch.
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
####
package AI::SimulatedAnnealing;

use 5.010001;
use strict;
use warnings;
use utf8;

use English "-no_match_vars";
use Hash::Util ("lock_keys");
use List::Util ("first", "max", "min", "sum");
use POSIX ("ceil", "floor");
use Scalar::Util ("looks_like_number");

use Exporter;

# Version:
our $VERSION = '1.02';

# Specify default exports:
our @ISA = ("Exporter");
our @EXPORT = (
  "anneal",
  );

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

my $TEMPERATURE_MULTIPLIER = 0.95;

# The anneal() function takes a reference to an array of number
# specifications (which are references to hashes containing "LowerBound",
# "UpperBound", and "Precision" fields), a reference to a cost function
# (which takes a list of numbers matching the specifications and returns a
# number representing a cost to be minimized), and a positive integer
# specifying the number of randomization cycles to perform at each
# temperature during the annealing process.
#
# The function returns a reference to an array containing the
# optimized list of numbers.
sub anneal {
    my $number_specs = validate_number_specs($_[0]);
    my $cost_function = $_[1];
    my $cycles_per_temperature = $_[2];

    my $current_temperature;
    my $lowest_cost;

    my @integral_lower_bounds;
    my @integral_upper_bounds;
    my @optimized_list;

    $current_temperature = 1;

    for my $number_spec (@{ $number_specs }) {
        push @integral_lower_bounds, int($number_spec->{"LowerBound"}
          * (10 ** $number_spec->{"Precision"}));
        push @integral_upper_bounds, int($number_spec->{"UpperBound"}
          * (10 ** $number_spec->{"Precision"}));

        if ($integral_upper_bounds[-1] - $integral_lower_bounds[-1]
          > $current_temperature) {
            $current_temperature
              = $integral_upper_bounds[-1] - $integral_lower_bounds[-1];
        } # end if
    } # next $number_spec

    while ($current_temperature > 0) {
        my @adjusted_lower_bounds;
        my @adjusted_upper_bounds;

        # Calculate the temperature-adjusted bounds:
        for my $dex (0..$#integral_lower_bounds) {
            if ($current_temperature >= $integral_upper_bounds[$dex]
              - $integral_lower_bounds[$dex] || !defined($lowest_cost)) {
                push @adjusted_lower_bounds, $integral_lower_bounds[$dex];
                push @adjusted_upper_bounds, $integral_upper_bounds[$dex];
            }
            else {
                my $adjusted_lower_bound;
                my $adjusted_upper_bound;
                my $half_range = $current_temperature / 2.0;

                if (floor($half_range) != $half_range) {
                    my $rand = rand();

                    if ($rand >= 0.5) {
                        $half_range = ceil($half_range);
                    }
                    else {
                        $half_range = floor($half_range);
                    } # end if
                } # end if

                $adjusted_lower_bound = int($optimized_list[$dex]
                  * (10 ** $number_specs->[$dex]->{"Precision"})
                  - $half_range);

                if ($adjusted_lower_bound < $integral_lower_bounds[$dex]) {
                    $adjusted_lower_bound = $integral_lower_bounds[$dex];
                }
                elsif ($adjusted_lower_bound + $current_temperature
                  > $integral_upper_bounds[$dex]) {
                    $adjusted_lower_bound = $integral_upper_bounds[$dex]
                      - $current_temperature;
                } # end if

                $adjusted_upper_bound
                  = $adjusted_lower_bound + $current_temperature;

                push @adjusted_lower_bounds, $adjusted_lower_bound;
                push @adjusted_upper_bounds, $adjusted_upper_bound;
            } # end if
        } # next $dex

        # Determine whether brute force is appropriate, and if so, use it:
        my $combinations
          = 1 + $adjusted_upper_bounds[0] - $adjusted_lower_bounds[0];

        for my $dex (1..$#adjusted_upper_bounds) {
            if ($combinations > $cycles_per_temperature) {
                $combinations = 0;
                last;
            } # end if

            $combinations *= (1 + $adjusted_upper_bounds[$dex]
              - $adjusted_lower_bounds[$dex]);
        } # next $dex

        if ($combinations > 0 && $combinations <= $cycles_per_temperature) {
            my @adjusted_number_specs;

            # Create the adjusted number specifications:
            for my $dex (0..$#{ $number_specs }) {
                push @adjusted_number_specs, {
                  "LowerBound" => $adjusted_lower_bounds[$dex]
                  / (10 ** $number_specs->[$dex]->{"Precision"}),
                  "UpperBound" => $adjusted_upper_bounds[$dex]
                  / (10 ** $number_specs->[$dex]->{"Precision"}),
                  "Precision" => $number_specs->[$dex]->{"Precision"}};
            } # next $dex

            # Perform the brute-force analysis:
            @optimized_list = @{ use_brute_force(
              \@adjusted_number_specs, $cost_function) };

            # Break out of the temperature-reduction loop:
            last;
        } # end if

        # Perform randomization cycles:
        for (1..$cycles_per_temperature) {
            my @candidate_list;
            my $cost;

            for my $dex (0..$#adjusted_lower_bounds) {
                my $rand = rand();
                my $addend = floor($rand * (1 + $adjusted_upper_bounds[$dex]
                  - $adjusted_lower_bounds[$dex]));

                push @candidate_list,
                  ($adjusted_lower_bounds[$dex] + $addend)
                  / (10 ** $number_specs->[$dex]->{"Precision"});
            } # next $dex

            $cost = $cost_function->(\@candidate_list);

            unless (defined($lowest_cost) && $cost >= $lowest_cost) {
                $lowest_cost = $cost;
                @optimized_list = @candidate_list;
            } # end unless
        } # next cycle

        # Reduce the temperature:
        $current_temperature = floor(
          $current_temperature * $TEMPERATURE_MULTIPLIER);
    } # end while

    return \@optimized_list;
} # end sub

####
# Private helper functions for use by this module:

# The use_brute_force() function takes a reference to an array of number
# specifications (which are references to hashes containing "LowerBound",
# "UpperBound", and "Precision" fields) and a reference to a cost function
# (which takes a list of numbers matching the specifications and returns a
# number representing a cost to be minimized).  The method tests every
# possible combination of numbers matching the specifications and returns a
# reference to an array containing the optimal numbers, where "optimal"
# means producing the lowest cost.
sub use_brute_force {
    my $number_specs = validate_number_specs($_[0]);
    my $cost_function = $_[1];

    my @optimized_list;
    my @lists;
    my @cursors;

    # Populate the list of lists of numbers:
    for my $number_spec (@{ $number_specs }) {
        my @list;
        my $num = $number_spec->{"LowerBound"};

        while ($num <= $number_spec->{"UpperBound"}) {
            push @list, $num;
            $num += 1 / (10 ** $number_spec->{"Precision"});
        } # end while

        push @lists, \@list;
    } # next $number_spec

    # Populate @cursors with the starting position for each list of numbers:
    for (0..$#lists) {
        push @cursors, 0;
    } # next

    # Perform the tests:
    my $lowest_cost = undef;
    my $finished = $FALSE;

    do {
        # Perform a test using the current cursors:
        my @candidate_list;
        my $cost;

        for my $dex (0..$#lists) {
            push @candidate_list, $lists[$dex]->[$cursors[$dex]];
        } # next $dex

        $cost = $cost_function->(\@candidate_list);

        unless (defined($lowest_cost) && $cost >= $lowest_cost) {
            $lowest_cost = $cost;
            @optimized_list = @candidate_list;
        } # end unless

        # Adjust the cursors for the next test if not finished:
        for my $dex (reverse(0..$#lists)) {
            my $cursor = $cursors[$dex];

            if ($cursor < $#{ $lists[$dex] }) {
                $cursor++;
                $cursors[$dex] = $cursor;
                last;
            }
            elsif ($dex == 0) {
                $finished = $TRUE;
                last;
            }
            else {
                $cursors[$dex] = 0;
            } # end if
        } # next $dex
    } until ($finished);

    # Return the result:
    return \@optimized_list;
} # end sub

# The validate_number_specs() function takes a reference to an array of
# number specifications (which are references to hashes with "LowerBound",
# "UpperBound", and "Precision" fields) and returns a reference to a version
# of the array in which bounds with higher precision than that specified
# have been rounded inward.  If a number specification is not valid, the
# function calls "die" with an error message.
sub validate_number_specs {
    my $raw_number_specs = $_[0];
    my @processed_number_specs = @{ $raw_number_specs };

    for my $number_spec (@processed_number_specs) {
        my $lower_bound = $number_spec->{"LowerBound"};
        my $upper_bound = $number_spec->{"UpperBound"};
        my $precision = $number_spec->{"Precision"};

        unless (looks_like_number($precision)
          && int($precision) == $precision
          && $precision >= 0 && $precision <= 4) {
            die "ERROR:  In a number specification, the precision must be "
              . "an integer in the range 0 to 4.\n";
        } # end unless

        unless (looks_like_number($lower_bound)
          && looks_like_number($upper_bound)
          && $upper_bound > $lower_bound
          && $upper_bound <= 10 ** (4 - $precision)
          && $lower_bound >= -1 * (10 ** (4 - $precision))) {
            die "ERROR:  In a number specification, the lower and upper "
              . "bounds must be numbers such that the upper bound is "
              . "greater than the lower bound, the upper bound is not "
              . "greater than 10 to the power of (4 - p) where p is the "
              . "precision, and the lower bound is not less than -1 times "
              . "the result of taking 10 to the power of (4 - p).\n";
        } # end unless

        # Round the bounds inward as necessary:
        my $integral_lower_bound = ceil( $lower_bound * (10 ** $precision));
        my $integral_upper_bound = floor($upper_bound * (10 ** $precision));

        $number_spec->{"LowerBound"}
          = $integral_lower_bound / (10 ** $precision);
        $number_spec->{"UpperBound"}
          = $integral_upper_bound / (10 ** $precision);
    } # next $number_spec

    return \@processed_number_specs;
} # end sub

# Module return value:
1;
__END__

=head1 NAME

AI::SimulatedAnnealing - optimize a list of numbers according to a specified
cost function.

=head1 SYNOPSIS

  use AI::SimulatedAnnealing;

  $optimized_list = anneal(
    $number_specs, $cost_function, $cycles_per_temperature);

=head1 DESCRIPTION

This module provides a single public function, anneal(), that optimizes
a list of numbers according to a specified cost function.

Each number to be optimized has a lower bound, an upper bound, and a
precision, where the precision is an integer in the range 0 to 4 that
specifies the number of decimal places to which all instances of the
number will be rounded.  The upper bound must be greater than the
lower bound but not greater than 10 to the power of (4 - p), where "p"
is the precision.  The lower bound must be not less than -1 times the
result of taking 10 to the power of (4 - p).

A bound that has a higher degree of precision than that specified for
the number to which the bound applies is rounded inward (that is,
downward for an upper bound and upward for a lower bound) to the
nearest instance of the specified precision.

The attributes of a number (bounds and precision) are encapsulated
within a number specification, which is a reference to a hash
containing "LowerBound", "UpperBound", and "Precision" fields.

The anneal() function takes a reference to an array of number
specifications, a cost function, and a positive integer specifying
the number of randomization cycles per temperature to perform.  The
anneal() function returns a reference to an array having the same
length as the array of number specifications.  The returned list
represents the optimal list of numbers matching the specified
attributes, where "optimal" means producing the lowest cost.

The cost function must take a reference to an array of numbers that
match the number specifications.  The function must return a single
number representing a cost to be minimized.

In order to work efficiently with the varying precisions, the anneal()
function converts each bound to an integer by multiplying it by 10 to
the power of the precision; then the function performs the temperature
reductions and randomization cycles (which include tests performed via
calls to the cost function) on integers in the resulting ranges.  When
passing an integer to the cost function or when storing the integer in
a collection of numbers to be returned by the function, anneal() first
converts the integer back to the appropriate decimal number by
dividing the integer by 10 to the power of the precision.

The initial temperature is the size of the largest range after the
bounds have been converted to integers.  During each temperature
reduction, the anneal() function multiplies the temperature by 0.95
and then rounds the result down to the nearest integer (if the result
isn't already an integer).  When the temperature reaches zero,
annealing is immediately terminated.

  NOTE:  Annealing can sometimes complete before the temperature
  reaches zero if, after a particular temperature reduction, a
  brute-force optimization approach (that is, testing every possible
  combination of numbers within the subranges determined by the new
  temperature) would produce a number of tests that is less than or
  equal to the specified cycles per temperature.  In that case, the
  anneal() function performs the brute-force optimization to complete
  the annealing process.

After a temperature reduction, the anneal() function determines each
new subrange such that the current optimal integer from the total
range is as close as possible to the center of the new subrange.
When there is a tie between two possible positions for the subrange
within the total range, a "coin flip" decides.

=head1 PREREQUISITES

This module requires Perl 5, version 5.10.1 or later.

=head1 METHODS

=over

=item anneal($number_specs, $cost_function, $cycles_per_temperature);

The anneal() function takes a reference to an array of number specifications
(which are references to hashes containing "LowerBound", "UpperBound", and
"Precision" fields), a code reference pointing to a cost function (which
takes a list of numbers matching the specifications and returns a number
representing a cost to be minimized), and a positive integer specifying the
number of randomization cycles to perform at each temperature.

The function returns a reference to an array containing the optimized list
of numbers.

=back

=head1 AUTHOR

Benjamin Fitch, <blernflerkl@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Benjamin Fitch.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
