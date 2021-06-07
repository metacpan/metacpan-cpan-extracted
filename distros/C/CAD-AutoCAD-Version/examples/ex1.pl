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
#     [14] "AC1016",
#     [15] "AC1017",
#     [16] "AC1018",
#     [17] "AC1019",
#     [18] "AC1020",
#     [19] "AC1021",
#     [20] "AC1022",
#     [21] "AC1023",
#     [22] "AC1024",
#     [23] "AC1025",
#     [24] "AC1026",
#     [25] "AC1027",
#     [26] "AC1028",
#     [27] "AC1029",
#     [28] "AC1030",
#     [29] "AC1031",
#     [30] "AC1032",
#     [31] "AC1033",
#     [32] "AC1034",
#     [33] "AC1035",
#     [34] "AC2.10",
#     [35] "AC2.21",
#     [36] "AC2.22",
#     [37] "MC0.0"
# ]