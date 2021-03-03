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
#     [20] "PCIMPRICH",
#     [21] "PEK",
#     [22] "POPEL",
#     [23] "PSME",
#     [24] "RUR",
#     [25] "RVASICEK",
#     [26] "SARFY",
#     [27] "SEIDLJAN",
#     [28] "SKIM",
#     [29] "SMRZ",
#     [30] "STRAKA",
#     [31] "TKR",
#     [32] "TRIPIE",
#     [33] "TYNOVSKY",
#     [34] "VARISD",
#     [35] "VASEKD",
#     [36] "YENYA",
#     [37] "ZABA",
#     [38] "ZEMAN",
#     [39] "ZOUL"
# ]