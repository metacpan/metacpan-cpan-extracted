#!perl
use strict;
use warnings;
use Test::More tests => 1;


# This stuff is already run in Build.PL, but I need it in the test suite too,
# because the CPAN reporters don't show me the Build.PL output.

my $vers_output = `sox --version`;

if (defined $vers_output) {
    my ($soxver) = $vers_output =~ /v([\d.]+)/
        or die "Strange sox --version output: $vers_output\n";
    warn "SoX version $soxver found.\n";
} else {
    die "Could not run the sox program; please make sure it is installed.\n";
}

SKIP: {
    # I must plan a test, otherwise the test suite complains
    skip 'this test program is only needed for its diagnostics', 1;
}
