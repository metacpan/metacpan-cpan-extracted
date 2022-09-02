#!/usr/bin/env perl

use strict;
use warnings;

use Check::Fork qw(check_fork);
use Check::Socket qw(check_socket);

if (! check_fork()) {
        print "We couldn't fork.\n";
        print "Error message: $Check::Fork::ERROR_MESSAGE\n";
} elsif (! check_socket()) {
        print "We couldn't use socket communication.\n";
        print "Error message: $Check::Socket::ERROR_MESSAGE\n";
} else {
        print "We could use fork and socket communication.\n";
}

# Output on Unix:
# We could use fork and socket communication.