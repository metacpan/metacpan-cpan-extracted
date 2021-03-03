#!/usr/bin/env perl

use strict;
use warnings;

use Acme::CPANAuthors;

# Create object.
my $authors = Acme::CPANAuthors->new('Czech');

# Get number of Czech CPAN authors.
my $count = $authors->count;

# Print out.
print "Count of Czech CPAN authors: $count\n";

# Output:
# Count of Czech CPAN authors: 40