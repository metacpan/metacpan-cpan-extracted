#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use CAD::AutoCAD::Version;

# Object.
my $obj = CAD::AutoCAD::Version->new;

# Create image.
my @acad_identifiers_real = $obj->list_of_acad_identifiers_real;

# Print out type.
p @acad_identifiers_real;

# Output:
# [
#     [0]  "MC0.0"
#     [1]  "AC1.2",
#     [2]  "AC1.40",
#     [3]  "AC1.50",
#     [4]  "AC2.10",
#     [5]  "AC2.21",
#     [6]  "AC2.22",
#     [7]  "AC1001",
#     [8]  "AC1002",
#     [9]  "AC1003",
#     [10] "AC1004",
#     [11] "AC1006",
#     [12] "AC1009",
#     [13] "AC1012",
#     [14] "AC1014",
#     [15] "AC1015",
#     [16] "AC1018",
#     [17] "AC1021",
#     [18] "AC1024",
#     [19] "AC1027",
#     [20] "AC1032",
# ]