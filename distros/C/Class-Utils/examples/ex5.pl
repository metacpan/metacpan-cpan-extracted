#!/usr/bin/env perl

use strict;
use warnings;

use Class::Utils qw(split_params);

# Example parameters.
my @params = qw(foo bar bad value);

# Set bad params.
my ($main_params_ar, $other_params_ar) = split_params(['foo'], @params);

# Print out.
print "Main params:\n";
print "* ".(join ': ', @{$main_params_ar});
print "\n";
print "Other params:\n";
print "* ".(join ': ', @{$other_params_ar});
print "\n";

# Output:
# Main params:
# * foo: bar
# Other params:
# * bad: value