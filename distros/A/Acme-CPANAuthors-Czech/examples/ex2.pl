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
#     [21] "MJFO",
#     [22] "PAJAS",
#     [23] "PAJOUT",
#     [24] "PASKY",
#     [25] "PCIMPRICH",
#     [26] "PEK",
#     [27] "PETRIS",
#     [28] "PKUBANEK",
#     [29] "POPEL",
#     [30] "PSME",
#     [31] "RUR",
#     [32] "RVASICEK",
#     [33] "SARFY",
#     [34] "SEIDLJAN",
#     [35] "SKIM",
#     [36] "SMRZ",
#     [37] "STRAKA",
#     [38] "TKR",
#     [39] "TPODER",
#     [40] "TRIPIE",
#     [41] "TYNOVSKY",
#     [42] "VARISD",
#     [43] "VASEKD",
#     [44] "YENYA",
#     [45] "ZABA",
#     [46] "ZEMAN",
#     [47] "ZOUL"
# ]