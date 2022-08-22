#!/usr/bin/env perl

use strict;
use warnings;

use Check::Socket qw(check_socket $ERROR_MESSAGE);

if (check_socket()) {
        print "We could use socket communication.\n";
} else {
        print "We couldn't use socket communication.\n";
        print "Error message: $ERROR_MESSAGE\n";
}

# Output on Unix:
# We could use socket communication.