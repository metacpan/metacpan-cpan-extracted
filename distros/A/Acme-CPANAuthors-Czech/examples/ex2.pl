#!/usr/bin/env perl

use strict;
use warnings;

use Acme::CPANAuthors;
use Data::Printer;

# Create object.
my $authors = Acme::CPANAuthors->new('Czech');

# Get all ids.
my @ids = $authors->id;

# Print out.
p @ids;

# Output:
# [
#     [0]  "CHOROBA",
#     [1]  "DANIELR",
#     [2]  "DANPEDER",
#     [3]  "DOUGLISH",
#     [4]  "HIHIK",
#     [5]  "HOLCAPEK",
#     [6]  "HPA",
#     [7]  "JANPAZ",
#     [8]  "JANPOM",
#     [9]  "JENDA",
#     [10] "JIRA",
#     [11] "JSPICAK",
#     [12] "KLE",
#     [13] "KOLCON",
#     [14] "MAJLIS",
#     [15] "MICHALS",
#     [16] "MILSO",
#     [17] "MJFO",
#     [18] "PAJAS",
#     [19] "PASKY",
#     [20] "PEK",
#     [21] "POPEL",
#     [22] "PSME",
#     [23] "RUR",
#     [24] "RVASICEK",
#     [25] "SEIDLJAN",
#     [26] "SKIM",
#     [27] "SMRZ",
#     [28] "STRAKA",
#     [29] "TKR",
#     [30] "TRIPIE",
#     [31] "TYNOVSKY",
#     [32] "VARISD",
#     [33] "VASEKD",
#     [34] "YENYA",
#     [35] "ZABA",
#     [36] "ZEMAN",
#     [37] "ZOUL"
# ]