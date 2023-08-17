#!/usr/bin/env perl

use strict;
use warnings;

use Acme::CPANAuthors;
use Data::Printer;

# Create object.
my $authors = Acme::CPANAuthors->new('Slovak');

# Get all ids.
my @ids = $authors->id;

# Print out.
p @ids;

# Output:
# [
#     [0]  "BARNEY",
#     [1]  "JKUTEJ",
#     [2]  "KOZO",
#     [3]  "LKUNDRAK",
#     [4]  "PALI",
#     [5]  "SAMSK",
# ]