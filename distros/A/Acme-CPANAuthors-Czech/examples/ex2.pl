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
#     [10] "JENDA",
#     [11] "JIRA",
#     [12] "JSPICAK",
#     [13] "KLE",
#     [14] "KOLCON",
#     [15] "MAJLIS",
#     [16] "MICHALS",
#     [17] "MILSO",
#     [18] "MJFO",
#     [19] "PAJAS",
#     [20] "PAJOUT",
#     [21] "PASKY",
#     [22] "PCIMPRICH",
#     [23] "PEK",
#     [24] "PETRIS",
#     [25] "PKUBANEK",
#     [26] "POPEL",
#     [27] "PSME",
#     [28] "RUR",
#     [29] "RVASICEK",
#     [30] "SARFY",
#     [31] "SEIDLJAN",
#     [32] "SKIM",
#     [33] "SMRZ",
#     [34] "STRAKA",
#     [35] "TKR",
#     [36] "TPODER",
#     [37] "TRIPIE",
#     [38] "TYNOVSKY",
#     [39] "VARISD",
#     [40] "VASEKD",
#     [41] "YENYA",
#     [42] "ZABA",
#     [43] "ZEMAN",
#     [44] "ZOUL"
# ]