#!/usr/bin/env perl

use strict;
use warnings;

use Acme::CPANAuthors;

# Create object.
my $authors = Acme::CPANAuthors->new('Slovak');

# Get number of Slovak CPAN authors.
my $count = $authors->count;

# Print out.
print "Count of Slovak CPAN authors: $count\n";

# Output:
# Count of Slovak CPAN authors: 6