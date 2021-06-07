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
#     [2]  "AC1.3",
#     [3]  "AC1.40",
#     [4]  "AC1.50",
#     [5]  "AC2.10",
#     [6]  "AC2.21",
#     [7]  "AC2.22",
#     [8]  "AC1001",
#     [9]  "AC1002",
#     [10] "AC1003",
#     [11] "AC1004",
#     [12] "AC1006",
#     [13] "AC1009",
#     [14] "AC1012",
#     [15] "AC1013",
#     [16] "AC1014",
#     [17] "AC1015",
#     [18] "AC1016",
#     [19] "AC1017",
#     [20] "AC1018",
#     [21] "AC1019",
#     [22] "AC1020",
#     [23] "AC1021",
#     [24] "AC1022",
#     [25] "AC1023",
#     [26] "AC1024",
#     [27] "AC1025",
#     [28] "AC1026",
#     [29] "AC1027",
#     [30] "AC1028",
#     [31] "AC1029",
#     [32] "AC1030",
#     [33] "AC1031",
#     [34] "AC1032",
#     [35] "AC1033",
#     [36] "AC1034",
#     [37] "AC1035",
# ]