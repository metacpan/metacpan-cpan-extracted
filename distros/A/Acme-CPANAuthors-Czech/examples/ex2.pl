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
#     [1]  "CONTYK",
#     [2]  "DANIELR",
#     [3]  "DANPEDER",
#     [4]  "DOUGLISH",
#     [5]  "HIHIK",
#     [6]  "HOLCAPEK",
#     [7]  "HPA",
#     [8]  "JANPAZ",
#     [9]  "JANPOM",
#     [10]  "JENDA",
#     [11] "JIRA",
#     [12] "JSPICAK",
#     [13] "KLE",
#     [14] "KOLCON",
#     [15] "MAJLIS",
#     [16] "MICHALS",
#     [17] "MILSO",
#     [18] "MJFO",
#     [19] "PAJAS",
#     [20] "PASKY",
#     [21] "PCIMPRICH",
#     [22] "PEK",
#     [23] "POPEL",
#     [24] "PSME",
#     [25] "RUR",
#     [26] "RVASICEK",
#     [27] "SARFY",
#     [28] "SEIDLJAN",
#     [29] "SKIM",
#     [30] "SMRZ",
#     [31] "STRAKA",
#     [32] "TKR",
#     [33] "TRIPIE",
#     [34] "TYNOVSKY",
#     [35] "VARISD",
#     [36] "VASEKD",
#     [37] "YENYA",
#     [38] "ZABA",
#     [39] "ZEMAN",
#     [40] "ZOUL"
# ]