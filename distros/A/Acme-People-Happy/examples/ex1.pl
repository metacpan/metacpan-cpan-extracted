#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Acme::People::Happy;

# Object.
my $people = Acme::People::Happy->new;

# Are you happy?
print $people->are_you_happy."\n";

# Output like:
# Yes, i'm.