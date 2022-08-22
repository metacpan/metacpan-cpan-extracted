#!/usr/bin/env perl

use strict;
use warnings;

use Check::Fork qw(check_fork $ERROR_MESSAGE);

if (check_fork()) {
        print "We could fork.\n";
} else {
        print "We couldn't fork.\n";
        print "Error message: $ERROR_MESSAGE\n";
}

# Output on Unix with Config{'d_fork'} set:
# We could fork.

# Output on Unix without Config{'d_fork'} set:
# We couldn't fork.
# Error message: No fork() routine available.

# Output on Windows without $Config{'useithreads'} set:
# We couldn't fork.
# Error message: MSWin32: No interpreter-based threading implementation.