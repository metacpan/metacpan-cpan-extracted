package StderrNoise;
# Loaded with -M in a child perl of t/87: writes to STDERR at load time, as an
# old Test::More / Test::Builder does with its deprecation warnings.
use strict;
use warnings;

print STDERR "StderrNoise: a line on the child's stderr\n";

1;
