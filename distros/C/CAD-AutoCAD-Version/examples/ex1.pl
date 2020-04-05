#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use CAD::AutoCAD::Version;

# Object.
my $obj = CAD::AutoCAD::Version->new;

# Create image.
my @acad_identifiers = sort $obj->list_of_acad_identifiers;

# Print out type.
p @acad_identifiers;

# Output:
# [
#     [0]  "AC1.2",
#     [1]  "AC1.40",
#     [2]  "AC1.50",
#     [3]  "AC1001",
#     [4]  "AC1002",
#     [5]  "AC1003",
#     [6]  "AC1004",
#     [7]  "AC1006",
#     [8]  "AC1009",
#     [9]  "AC1012",
#     [10] "AC1014",
#     [11] "AC1015",
#     [12] "AC1018",
#     [13] "AC1021",
#     [14] "AC1024",
#     [15] "AC1027",
#     [16] "AC1032",
#     [17] "AC2.10",
#     [18] "AC2.21",
#     [19] "AC2.22",
#     [20] "MC0.0"
# ]