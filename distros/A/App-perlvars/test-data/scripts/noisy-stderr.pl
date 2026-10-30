use strict;
use warnings;

# Compile-time code runs when the wrapped file is required for analysis. Its
# output must not leak through perlvars.
BEGIN { print STDERR "compile-time noise from the analyzed file\n"; }

sub run {
    my $unused_noisy;
    return 1;
}

run();
