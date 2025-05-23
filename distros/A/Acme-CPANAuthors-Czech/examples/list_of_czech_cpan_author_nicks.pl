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
#     [0]  "ATG",
#     [1]  "BULB",
#     [2]  "CHOROBA",
#     [3]  "CONTYK",
#     [4]  "DANIELR",
#     [5]  "DANPEDER",
#     [6]  "DOUGLISH",
#     [7]  "DPOKORNY",
#     [8]  "HIHIK",
#     [9]  "HOLCAPEK",
#     [10] "HPA",
#     [11] "JANPAZ",
#     [12] "JANPOM",
#     [13] "JENDA",
#     [14] "JIRA",
#     [15] "JSPICAK",
#     [16] "KLE",
#     [17] "KOLCON",
#     [18] "MAJLIS",
#     [19] "MICHALS",
#     [20] "MILSO",
#     [21] "MIK",
#     [22] "MJFO",
#     [23] "PAJAS",
#     [24] "PAJOUT",
#     [25] "PASKY",
#     [26] "PCIMPRICH",
#     [27] "PEK",
#     [28] "PETRIS",
#     [29] "PKUBANEK",
#     [30] "POPEL",
#     [31] "PSME",
#     [32] "RADIUSCZ"
#     [33] "RUR",
#     [34] "RVASICEK",
#     [35] "SARFY",
#     [36] "SEIDLJAN",
#     [37] "SKIM",
#     [38] "SMRZ",
#     [39] "STRAKA",
#     [40] "TKR",
#     [41] "TPODER",
#     [42] "TRIPIE",
#     [43] "TYNOVSKY",
#     [44] "VARISD",
#     [45] "VASEKD",
#     [46] "YENYA",
#     [47] "ZABA",
#     [48] "ZEMAN",
#     [49] "ZOUL"
# ]