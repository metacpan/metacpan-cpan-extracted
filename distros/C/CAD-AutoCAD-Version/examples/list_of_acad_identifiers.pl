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
#     [1]  "AC1.3",
#     [2]  "AC1.40",
#     [3]  "AC1.50",
#     [4]  "AC1001",
#     [5]  "AC1002",
#     [6]  "AC1003",
#     [7]  "AC1004",
#     [8]  "AC1006",
#     [9]  "AC1009",
#     [10] "AC1012",
#     [11] "AC1013",
#     [12] "AC1014",
#     [13] "AC1015",
#     [14] "AC1018",
#     [15] "AC1021",
#     [16] "AC1024",
#     [17] "AC1027",
#     [18] "AC1032",
#     [19] "AC1500",
#     [20] "AC2.10",
#     [21] "AC2.21",
#     [22] "AC2.22",
#     [23] "MC0.0"
# ]