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
#     [25] "SARFY",
#     [26] "SEIDLJAN",
#     [27] "SKIM",
#     [28] "SMRZ",
#     [29] "STRAKA",
#     [30] "TKR",
#     [31] "TRIPIE",
#     [32] "TYNOVSKY",
#     [33] "VARISD",
#     [34] "VASEKD",
#     [35] "YENYA",
#     [36] "ZABA",
#     [37] "ZEMAN",
#     [38] "ZOUL"
# ]