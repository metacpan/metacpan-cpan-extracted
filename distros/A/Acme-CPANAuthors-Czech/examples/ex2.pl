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
#     [23] "PETRIS",
#     [24] "PKUBANEK",
#     [25] "POPEL",
#     [26] "PSME",
#     [27] "RUR",
#     [28] "RVASICEK",
#     [29] "SARFY",
#     [30] "SEIDLJAN",
#     [31] "SKIM",
#     [32] "SMRZ",
#     [33] "STRAKA",
#     [34] "TKR",
#     [35] "TPODER",
#     [36] "TRIPIE",
#     [37] "TYNOVSKY",
#     [38] "VARISD",
#     [39] "VASEKD",
#     [40] "YENYA",
#     [41] "ZABA",
#     [42] "ZEMAN",
#     [43] "ZOUL"
# ]