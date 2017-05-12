#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
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
#     [5]  "HPA",
#     [6]  "JANPAZ",
#     [7]  "JANPOM",
#     [8]  "JENDA",
#     [9]  "JIRA",
#     [10] "JSPICAK",
#     [11] "KLE",
#     [12] "KOLCON",
#     [13] "MAJLIS",
#     [14] "MICHALS",
#     [15] "MILSO",
#     [16] "MJFO",
#     [17] "PAJAS",
#     [18] "PASKY",
#     [19] "PEK",
#     [20] "POPEL",
#     [21] "PSME",
#     [22] "RUR",
#     [23] "RVASICEK",
#     [24] "SEIDLJAN",
#     [25] "SKIM",
#     [26] "SMRZ",
#     [27] "STRAKA",
#     [28] "TKR",
#     [29] "TRIPIE",
#     [30] "TYNOVSKY",
#     [31] "VASEKD",
#     [32] "YENYA",
#     [33] "ZABA",
#     [34] "ZEMAN",
#     [35] "ZOUL"
# ]