#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use CAD::Format::DWG::Version;

# Object.
my $obj = CAD::Format::DWG::Version->new;

# Create image.
my @dwg_identifiers = $obj->list_of_dwg_identifiers;

# Print out type.
p @dwg_identifiers;

# Output:
# [
#     [0]  "MC0.0",
#     [1]  "AC1.2",
#     [2]  "AC1.40",
#     [3]  "AC1.50",
#     [4]  "AC2.10",
#     [5]  "AC1001",
#     [6]  "AC1002",
#     [7]  "AC1003",
#     [8]  "AC1004",
#     [9]  "AC1006",
#     [10] "AC1009",
#     [11] "AC1010",
#     [12] "AC1011",
#     [13] "AC1012",
#     [14] "AC1013",
#     [15] "AC1014",
#     [16] "AC1500",
#     [17] "AC1015",
#     [18] "AC402a",
#     [19] "AC402b",
#     [20] "AC1018",
#     [21] "AC1021",
#     [22] "AC1024",
#     [23] "AC1027",
#     [24] "AC1032",
#     [25] "AC103-4"
# ]