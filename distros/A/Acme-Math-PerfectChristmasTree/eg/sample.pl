#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../lib");
use Acme::Math::PerfectChristmasTree qw/calc_perfect_christmas_tree/;

my %perfect_tree = calc_perfect_christmas_tree(140);

print $perfect_tree{'star_or_fairy_height'};
