package Local::PkgNoisy;

use strict;
use warnings;

# A file with a package statement is analyzed directly. Its compile-time code
# still runs when Test::Vars requires it; that output (and any stray TAP) must
# not leak through perlvars, while the genuine finding below is still reported.
BEGIN { print STDERR "compile-time noise from a packaged file\n"; }

sub noisy {
    my $unused_pkg_var = 42;
    return;
}

1;
